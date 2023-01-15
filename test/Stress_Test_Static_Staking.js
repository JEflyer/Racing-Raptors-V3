// const { expect } = require("chai");
// const { ethers } = require("hardhat");

const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("Testing the gas consumption on 3 seperate reward calculation algorithms", () => {

    async function setup() {
        //Get signers
        const [deployer, user1, user2, user3, attacker] = await ethers.getSigners();

        //Get contract factories
        const minterFactory = await ethers.getContractFactory("TestMinter", deployer)
        const statsFactory = await ethers.getContractFactory("TestStats", deployer)
        const tokenFactory = await ethers.getContractFactory("TestToken", deployer)
        const ssFactory = await ethers.getContractFactory("StaticStaking", deployer)


        //Deploy Test Minter
        const minter = await minterFactory.deploy([user1.address, user2.address, user3.address])

        //Deploy Tokens
        const raptorCoin = await tokenFactory.deploy()
        const usd = await tokenFactory.deploy()

        //Deploy Test Stats
        const stats = await statsFactory.deploy()

        // constructor(address[] memory _minters, address _token, address _stats, address _rate){
        //Deploy Static Staking 
        const staking = await ssFactory.deploy([minter.address], raptorCoin.address, stats.address, stats.address)

        // Instantiate stats for the tokens minted
        // function instantiateStats(address minter, uint16 tokenId) external returns(bool){
        for (let i = 1; i <= 30; i++) {
            await stats.instantiateStats(minter.address, i);
        }

        await stats.connect(deployer).addMinter(minter.address)

        //Increase DR survived stat
        await stats.increaseDRSurvived(0, 1)
        await stats.increaseDRSurvived(0, 1)
        await stats.increaseDRSurvived(0, 1)
        await stats.increaseDRSurvived(0, 1)
        await stats.increaseDRSurvived(0, 2)
        await stats.increaseDRSurvived(0, 2)
        await stats.increaseDRSurvived(0, 2)
        await stats.increaseDRSurvived(0, 2)
        await stats.increaseDRSurvived(0, 2)
        await stats.increaseDRSurvived(0, 3)
        await stats.increaseDRSurvived(0, 4)
        await stats.increaseDRSurvived(0, 4)
        await stats.increaseDRSurvived(0, 5)

        //Give the staking contract permission to mint
        await raptorCoin.addApprovedAddress(staking.address)

        //Stake & unstake multiple times with multiple tokens
        // await minter.connect(user1).setApprovalForAll(staking.address, true)
        // await minter.connect(user2).setApprovalForAll(staking.address, true)
        // await minter.connect(user3).setApprovalForAll(staking.address, true)

        await minter.connect(user1).approve(staking.address, 1)
        await minter.connect(user1).approve(staking.address, 2)
        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(1, 0)
        await staking.connect(user1).stake(2, 0)
        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)


        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        await minter.connect(user1).approve(staking.address, 3)
        await minter.connect(user1).approve(staking.address, 4)
        await minter.connect(user1).approve(staking.address, 5)

        await staking.connect(user1).stake(3, 0)
        await staking.connect(user1).stake(4, 0)
        await staking.connect(user1).stake(5, 0)
        await staking.connect(user1).unstake(3, 0)
        await staking.connect(user1).unstake(5, 0)
        await staking.connect(user1).unstake(4, 0)

        return { deployer, user1, user2, user3, attacker, minter, raptorCoin, staking, usd, stats }
    }
    it("Test 1", async() => {

        const { deployer, user1, user2, user3, attacker, minter, raptorCoin, staking, usd, stats } = await loadFixture(setup)

        //Call claim function
        await staking.connect(user1).claim(0, 1);
    })
})