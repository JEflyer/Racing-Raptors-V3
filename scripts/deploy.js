const { ethers } = require("ethers")

//Deploy order


// ----------------------- UNISWAP -------------------------
//Uniswap Factory
const { abi: x, bytecode: y } = require("../artifacts/contracts/FlatFactory.sol/UniswapV2Factory.json")

//Uniswap Router
const { abi: x, bytecode: y } = require("../artifacts/contracts/FlatRouter.sol/UniswapV2Router02.json")
    // ----------------------- UNISWAP -------------------------

// ----------------------- MINTERS -------------------------
//Bud Minter
const { abi: x, bytecode: y } = require("../artifacts/contracts/budMinter.sol/BudMinter.json")

//Minter 1
const { abi: x, bytecode: y } = require("../artifacts/contracts/mainMinter.sol/MainMinter.json")

//Minter 2
const { abi: x, bytecode: y } = require("../artifacts/contracts/secondaryMinter.sol/SecondaryMinter.json")

//Minter 3
const { abi: x, bytecode: y } = require("../artifacts/contracts/thirdMinter.sol/ThirdMinter.json")

//Raptorcoin
const { abi: x, bytecode: y } = require("../artifacts/contracts/raptorCoin.sol/RaptorCoin.json")

//Claws
const { abi: x, bytecode: y } = require("../artifacts/contracts/ClawsToken.sol/Claws.json")
    // ----------------------- MINTERS -------------------------

// ----------------------- STAKING -------------------------
//RaptorCoin Staking
const { abi: x, bytecode: y } = require("")

//LP Staking
const { abi: x, bytecode: y } = require("")

//Strength Staking
const { abi: x, bytecode: y } = require("")

//Death Race Staking
const { abi: x, bytecode: y } = require("")
    // ----------------------- STAKING -------------------------

// ----------------------- UTILITY -------------------------
//Stats
const { abi: x, bytecode: y } = require("")

//Rate
const { abi: x, bytecode: y } = require("")

//Multi Sig
const { abi: x, bytecode: y } = require("")

//Game
const { abi: x, bytecode: y } = require("")

//LP Depositor
const { abi: x, bytecode: y } = require("")

//Signature Verifier
const { abi: x, bytecode: y } = require("")

//Viewer Betting
const { abi: x, bytecode: y } = require("")

//Marketplace
const { abi: x, bytecode: y } = require("")
    // ----------------------- UTILITY -------------------------