const { ethers } = require("ethers")
const config = require("./config.json").goerli

//Deploy order

// ----------------------- UNISWAP -------------------------
//Uniswap Factory
const { abi: uniswapFactoryABI, bytecode: uniswapFactoryBytecode } = require("../artifacts/contracts/FlatFactory.sol/UniswapV2Factory.json")

//Uniswap Router
const { abi: uniswapRouterABI, bytecode: uniswapRouterBytecode } = require("../artifacts/contracts/FlatRouter.sol/UniswapV2Router02.json")
    // ----------------------- UNISWAP -------------------------

// ----------------------- MINTERS -------------------------
//Bud Minter
const { abi: budMinterABI, bytecode: budMinterBytecode } = require("../artifacts/contracts/budMinter.sol/BudMinter.json")

//Minter 1
const { abi: minter1ABI, bytecode: minter1Bytecode } = require("../artifacts/contracts/mainMinter.sol/MainMinter.json")

//Minter 2
const { abi: minter2ABI, bytecode: minter2Bytecode } = require("../artifacts/contracts/secondaryMinter.sol/SecondaryMinter.json")

//Minter 3
const { abi: minter3ABI, bytecode: minter3Bytecode } = require("../artifacts/contracts/thirdMinter.sol/ThirdMinter.json")

//Raptorcoin
const { abi: raptorCoinABI, bytecode: raptorCoinBytecode } = require("../artifacts/contracts/raptorCoin.sol/RaptorCoin.json")

//Claws
const { abi: clawsABI, bytecode: clawsBytecode } = require("../artifacts/contracts/ClawsToken.sol/Claws.json")
    // ----------------------- MINTERS -------------------------

// ----------------------- STAKING -------------------------
//RaptorCoin Staking
const { abi: raptorCoinStakingABI, bytecode: raptorCoinStakingBytecode } = require("../artifacts/contracts/raptorCoinStaking.sol/RaptorCoinStaking.json")

//LP Staking
const { abi: lpStakingABI, bytecode: lpStakingBytecode } = require("../artifacts/contracts/LpStaking.sol/LpStaking.json")

//Strength Staking
const { abi: strengthStakingABI, bytecode: strengthStakingBytecode } = require("../artifacts/contracts/strengthStaking.sol/StrengthStaking.json")

//Death Race Staking
const { abi: deathRaceStakingABI, bytecode: deathRaceStakingBytecode } = require("../artifacts/contracts/staticStaking.sol/StaticStaking.json")
    // ----------------------- STAKING -------------------------  

// ----------------------- UTILITY -------------------------
//Stats
const { abi: statsABI, bytecode: statsBytecode } = require("../artifacts/contracts/stats.sol/Stats.json")

//Rate
const { abi: rateABI, bytecode: rateBytecode } = require("../artifacts/contracts/Rate.sol/Rate.json")

//Multi Sig
const { abi: multiSigABI, bytecode: multiSigBytecode } = require("../artifacts/contracts/multiSigNFTWallet.sol/Multisig.json")

//Game
const { abi: gameABI, bytecode: gameBytecode } = require("../artifacts/contracts/game.sol/GameV3.json")

//LP Depositor
const { abi: lpDepositorABI, bytecode: lpDepositorBytecode } = require("../artifacts/contracts/LpDepositor.sol/LpDepositor.json")

//Signature Verifier
const { abi: sigVerifierABI, bytecode: sigVerifierBytecode } = require("../artifacts/contracts/SignatureVerifier.sol/SignatureVerifier.json")

//Viewer Betting
const { abi: viewerBettingABI, bytecode: viewerBettingBytecode } = require("../artifacts/contracts/viewerBetting.sol/ViewerBetting.json")

//Marketplace
const { abi: marketplaceABI, bytecode: marketplaceBytecode } = require("../artifacts/contracts/marketplace.sol/Marketplace.json")
    // ----------------------- UTILITY -------------------------



const private = config.private

const AlchemyURL = config.provider_url

const provider = new ethers.providers.WebSocketProvider(AlchemyURL)

const wallet = new ethers.Wallet(private, provider)


// ----------------------- UNISWAP -------------------------
//Uniswap Factory
const uniswapFactoryFactory = new ethers.ContractFactory(abi, bytecode, wallet)

//Uniswap Router
const uniswapRouterFactory = new ethers.ContractFactory(uniswapRouterABI, uniswapRouterBytecode, wallet)
    // ----------------------- UNISWAP -------------------------

// ----------------------- MINTERS -------------------------
//Bud Minter
const budMinterFactory = new ethers.ContractFactory(budMinterABI, budMinterBytecode, wallet)

//Minter 1
const minter1Factory = new ethers.ContractFactory(minter1ABI, minter1Bytecode, wallet)

//Minter 2
const minter2Factory = new ethers.ContractFactory(minter2ABI, minter2Bytecode, wallet)

//Minter 3
const minter3Factory = new ethers.ContractFactory(minter3ABI, minter3Bytecode, wallet)

//Raptorcoin
const raptorCoinFactory = new ethers.ContractFactory(raptorCoinABI, raptorCoinBytecode, wallet)

//Claws
const clawsFactory = new ethers.ContractFactory(clawsABI, clawsBytecode, wallet)



// ----------------------- UTILITY -------------------------
//Stats
const statsFactory = new ethers.ContractFactory(statsABI, statsBytecode, wallet)

//Multi Sig
const multiSigFactory = new ethers.ContractFactory(multiSigABI, multiSigBytecode, wallet)

//Game
const gameFactory = new ethers.ContractFactory(gameABI, gameBytecode, wallet)

//Signature Verifier
const sigVerifierFactory = new ethers.ContractFactory(sigVerifierABI, sigVerifierBytecode, wallet)

//Rate
const rateFactory = new ethers.ContractFactory(rateABI, rateBytecode, wallet)

//LP Depositor
const lpDepositorFactory = new ethers.ContractFactory(lpDepositorABI, lpDepositorBytecode, wallet)

//Viewer Betting
const viewerBettingFactory = new ethers.ContractFactory(viewerBettingABI, viewerBettingBytecode, wallet)

//Marketplace
const marketplaceFactory = new ethers.ContractFactory(marketplaceABI, marketplaceBytecode, wallet)
    // ----------------------- UTILITY -------------------------

// ----------------------- STAKING -------------------------
//RaptorCoin Staking
const raptorCoinStakingFactory = new ethers.ContractFactory(raptorCoinStakingABI, raptorCoinStakingBytecode, wallet)

//LP Staking
const lpStakingFactory = new ethers.ContractFactory(lpStakingABI, lpStakingBytecode, wallet)

//Strength Staking
const strengthStakingFactory = new ethers.ContractFactory(strengthStakingABI, strengthStakingBytecode, wallet)

//Death Race Staking
const deathRaceStakingFactory = new ethers.ContractFactory(deathRaceStakingABI, deathRaceStakingBytecode, wallet)
    // ----------------------- STAKING -------------------------  


const WETH = config.weth

const ChainlinkSubscriptionID = config.subscription_id

const ChainlinkKeyHash = config.key_hash

const VRFCoordinator = config.vrf_coordinator

const usdTokens = config.usd_tokens


function log(string) {
    console.log(string)
}

async function start() {

    log("Starting to deploy upgraded uniswap V2 Factory")

    let uniswapFactory = await uniswapFactoryFactory.deploy(
        wallet.address
    )

    await uniswapFactory.deployed()

    log(`Uniswap Factory deployed: ${uniswapFactory.address}`)



    log("Starting to deploy uniswap V2 Router")

    let uniswapRouter = await uniswapRouterFactory.deploy(
        uniswapFactory.address,
        WETH
    )

    await uniswapRouter.deployed()

    log(`Uniswap Router deployed: ${uniswapRouter.address}`)



    log(`Starting to deploy Bud Minter`)

    let budMinter = await budMinterFactory.deploy()

    await budMinter.deployed()

    log(`Bud Minter deployed: ${budMinter.address}`)


    //Deploy stats
    log("Starting to deploy the stats contract")

    let stats = await statsFactory.deploy(budMinter.address)

    await stats.deployed()

    log(`Successfully deployed the stats contract: ${stats.address}`)


    //Deploy raptorcoin
    log("Starting to deploy the raptorcoin contract")

    //  constructor
    //     address _WMatic,
    //     address _uniswapV2RouterAddr,
    //     address _liquidityLockedAddress
    let raptorCoin = await raptorCoinFactory.deploy(
        weth,
        uniswapRouter.address
    )

    log(`Successfully deployed the raptorcoin contract: ${raptorCoin.address}`)

    //Deploy multisig
    log("Starting to deploy the multi sig contract")
    let multisig = await multiSigFactory.deploy(
        config.signers,
        raptorCoin.address
    )

    await multisig.deployed()

    log(`Successfully deployed the multi sig contract: ${multisig.address}`)


    log("Starting to deploy the signature verifier")

    let sigVerifier = await sigVerifierFactory.deploy(
        wallet.address
    )

    await sigVerifier.deployed()

    log(`Successfully deployed the signature verifier contract: ${sigVerifier.address}`)

    //Deploy game
    log("Starting to deploy the game")

    // constructor(
    //     address _stats,
    //     address _raptorCoin,
    //     address _communityWallet,
    //     address _vrfCoordinator,
    //     address _sigVerifier,
    //     uint64 _subscriptionId,
    //     bytes32 _keyHash,
    //     uint32 _distance,
    //     uint256 _fee
    let game = await gameFactory.deploy(
        stats.address,
        raptorCoin.address,
        multisig.address,
        VRFCoordinator,
        sigVerifier.address,
        ChainlinkSubscriptionID,
        ChainlinkKeyHash,
        10000,
        1000000
    )

    await game.deployed()

    log(`Successfully deployed the game contract: ${game.address}`)



    log(`Starting to deploy Minter 1`)

    //   constructor(
    //     uint64 _subscriptionId,
    //     address _vrfCoordinator,
    //     bytes32 _keyHash,
    //     string memory _name,
    //     string memory _symbol,
    //     address _stats,
    //     address[] memory _usdTokens
    let minter1 = await minter1Factory.deploy(
        ChainlinkSubscriptionID,
        VRFCoordinator,
        ChainlinkKeyHash,
        "Main Minter",
        "MM",
        stats.address,
        usdTokens
    )

    await minter1.deployed()

    log(`Successfully deployed minter 1: ${minter1.address}`)



    log("Starting to deploy minter 2")

    let minter2 = await minter2Factory.deploy(
        stats.address
    )

    await minter2.deployed()

    log(`Successfully deployed minter 2: ${minter2.address}`)



    log("Starting to deploy minter 3")

    // constructor(
    //     string memory _name,
    //     string memory _symbol,
    //     address _minter,
    //     address _stats,
    //     address[] memory _usdTokens,
    //     uint256 _breedingFee,
    //     address[] memory _payees,
    //     uint16[] memory _shares
    let minter3 = await minter3Factory.deploy(
        "Minter 3",
        "M3",
        minter1.address,
        stats.address,
        usdTokens,
        25000000,
        config.payees,
        config.shares
    )

    await minter3.deployed()

    log(`Successfully deployed minter 3: ${minter3.address}`)

    log(`Adding the minters to the stats contract`)

    await stats.addMinter(minter1.address)
    await stats.addMinter(minter2.address)
    await stats.addMinter(minter3.address)

    log("Finished adding the minters to the stats contract")


    log("Starting to deploy claws contract")

    let claws = await clawsFactory.deploy(
        raptorCoin.address
    )

    await claws.deployed()

    log(`Successfully deployed claws contract: ${claws.address}`)



    log("Starting to deploy the lpDepositor")

    // constructor(address _router,address _usd,address _raptorCoin,uint256 _amount){
    let lpDepositor = await lpDepositorFactory.deploy(
        uniswapRouter.address,
        usdTokens[0],
        raptorCoin.address,
        1000000000 //1k USD
    )

}

// //Rate
// const rateFactory = new ethers.ContractFactory(rateABI, rateBytecode, wallet)

// //Viewer Betting
// const viewerBettingFactory = new ethers.ContractFactory(viewerBettingABI, viewerBettingBytecode, wallet)

// //Marketplace
// const marketplaceFactory = new ethers.ContractFactory(marketplaceABI, marketplaceBytecode, wallet)
//     // ----------------------- UTILITY -------------------------

// // ----------------------- STAKING -------------------------
// //RaptorCoin Staking
// const raptorCoinStakingFactory = new ethers.ContractFactory(raptorCoinStakingABI, raptorCoinStakingBytecode, wallet)

// //LP Staking
// const lpStakingFactory = new ethers.ContractFactory(lpStakingABI, lpStakingBytecode, wallet)

// //Strength Staking
// const strengthStakingFactory = new ethers.ContractFactory(strengthStakingABI, strengthStakingBytecode, wallet)

// //Death Race Staking
// const deathRaceStakingFactory = new ethers.ContractFactory(deathRaceStakingABI, deathRaceStakingBytecode, wallet)
//     // ----------------------- STAKING -------------------------  

start()