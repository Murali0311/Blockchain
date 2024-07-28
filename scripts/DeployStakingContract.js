import { ethers } from "hardhat";

async function main() {
    // Define the addresses and parameters
    const ownerAddress = "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4";
    const nftAddress = "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB";
    const rewardTokenAddress = "0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB";
    const rewardRate = ethers.utils.parseUnits("1", 18); // 1 token per block
    const unbondingTime = 10; // Unbonding Time in blocks
    const rewardDelayTime = 5; // Reward delay Time in blocks

    // Deploy the NFTStaking contract
    const StakingContract = await ethers.getContractFactory("StakingContract");
    const stakingContract = await StakingContract.deploy(
        ownerAddress,
        nftAddress,
        rewardTokenAddress,
        rewardRate,
        unbondingTime,
        rewardDelayTime
    );

    await stakingContract.deployed();

    console.log("Staking Contract deployed to:", stakingContract.address);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
