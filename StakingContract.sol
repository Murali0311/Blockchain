// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract StakingContract is Ownable, UUPSUpgradeable, Pausable {
    IERC721 public NFT;
    IERC20 public rewardToken;

    struct Stake {
        uint256 claimedAt;
        uint256 stakedAt;
        uint256 tokenId;
    }

    mapping(address => Stake[]) public stakes;
    mapping(uint256 => address) public tokenOwner;

    uint256 public rewardRate; // tokens per block
    uint256 public unbondingTime;
    uint256 public rewardDelayTime;

    event Staked(address indexed user, uint256 tokenId, uint256 timestamp);
    event Unstaked(address indexed user, uint256 tokenId, uint256 timestamp);
    event RewardsClaimed(address indexed user, uint256 amount, uint256 timestamp);

    constructor(
        address _owner,
        IERC721 _NFT,
        IERC20 _rewardToken,
        uint256 _rewardRate,
        uint256 _unbondingTime,
        uint256 _rewardDelayTime
    ) Ownable(_owner) UUPSUpgradeable() Pausable() {
        NFT = _NFT;
        rewardToken = _rewardToken;
        rewardRate = _rewardRate;
        unbondingTime = _unbondingTime;
        rewardDelayTime = _rewardDelayTime;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function stake(uint256 tokenId) external whenNotPaused {
        NFT.transferFrom(msg.sender, address(this), tokenId);
        stakes[msg.sender].push(Stake(tokenId, block.number, block.number));
        tokenOwner[tokenId] = msg.sender;
        emit Staked(msg.sender, tokenId, block.number);
    }

    function unstake(uint256 tokenId) external whenNotPaused {
        require(tokenOwner[tokenId] == msg.sender, "NFTStaking: Not the owner");
        require(block.number >= stakes[msg.sender][getStakeIndex(msg.sender, tokenId)].stakedAt + unbondingTime, "NFTStaking: Unbonding Time not over");

        NFT.transferFrom(address(this), msg.sender, tokenId);
        removeStake(msg.sender, tokenId);
        emit Unstaked(msg.sender, tokenId, block.number);
    }

    function claimRewards() external whenNotPaused {
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < stakes[msg.sender].length; i++) {
            uint256 stakingDuration = block.number - stakes[msg.sender][i].claimedAt;
            totalRewards += stakingDuration * rewardRate;
            stakes[msg.sender][i].claimedAt = block.number;
        }
        rewardToken.transfer(msg.sender, totalRewards);
        emit RewardsClaimed(msg.sender, totalRewards, block.number);
    }

    function getStakeIndex(address user, uint256 tokenId) internal view returns (uint256) {
        for (uint256 i = 0; i < stakes[user].length; i++) {
            if (stakes[user][i].tokenId == tokenId) {
                return i;
            }
        }
        revert("NFTStaking: Token not found in stakes");
    }

    function removeStake(address user, uint256 tokenId) internal {
        uint256 index = getStakeIndex(user, tokenId);
        stakes[user][index] = stakes[user][stakes[user].length - 1];
        stakes[user].pop();
        delete tokenOwner[tokenId];
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }

    function pauseStaking() external onlyOwner {
        _pause();
    }

    function unpauseStaking() external onlyOwner {
        _unpause();
    }
}