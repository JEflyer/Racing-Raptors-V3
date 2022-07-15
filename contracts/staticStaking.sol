//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//Import the interface for the stats contract
import "./interfaces/IStats.sol";

//Imported the context library for safe usage of msg.sender
import "@openzeppelin/contracts/utils/Context.sol";

//Import the interface for ERC20
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//Import the interface for ERC721A
import "./ERC721A/IERC721A.sol";


contract StaticStaking is Context{

    //Stores the address of the admin of this contract
    address private admin;

    //Stores an instance of an ERC20 interface
    IERC20 private token;

    //Stores instances of the ERC721A interface
    IERC721A private minter1;
    IERC721A private minter2;

    //Stores an instance of the Stats interface
    IStats private stats;

    //This is the fixed reward that users will be receive at a minimum per block
    uint256 private stakingRewardPerBlock;

    //Stores the number of death races a given token for minter has survived
    mapping(uint8 => mapping(uint16 => uint64)) private DRSurvivals;

    //This is data specific to the token 
    struct StakeData {
        address staker;
        uint256 blockStakedOn;
        uint256 blockLastClaimed; 
    }

    //We store the above struct for a given token & minterindex
    mapping(uint8 => mapping(uint16 => StakeData)) private stakeData;

    //This is data specific to the user 
    struct UserData {
        uint8[] minterIndexes;
        uint16[] tokenIDs;
    }

    //Store the user data for a given address
    mapping(address => UserData) private userData;

    constructor(address _minter1, address _minter2, address _token, address _stats, uint256 _stakingRewardPerBlock){

        //Build instance of an ERC20 interface
        token = IERC20(_token);

        //Build instance of an ERC721A interface
        minter1 = IERC721A(_minter1);
        minter2 = IERC721A(_minter2);

        //Build an instance of the Stats contract interface
        stats = IStats(_stats);

        //Set admin as the deployer
        admin = _msgSender();

        //Store the fixed reward into storage
        stakingRewardPerBlock = _stakingRewardPerBlock;
    }

    function stake(uint16 tokenId, uint8 minterIndex) external {
        
        //Check that minterIndex is less than 2
        require(minterIndexc < 2, "ERR:MI");//MI => Minter Index

        //Get the address of the caller
        address caller = _msgSender();

        
        //Define an instance of the minter
        IERC721A memory minter;

        //Assign the minter to memory
        if(minterIndex == 0){
            minter = minter1;
        }else if(minterIndex == 1){
            minter = minter2;
        }  

        //Check that the caller owns the token for minter index
        require(minter.ownerOf(tokenId) == caller,"ERR:NO");//NO => Not Owner
        
        //Check that the caller has given this contract approval over the token being staked
        require(minter.getApproved(tokenId) == address(this), "ERR:NA");//NA => Not Approved

        //Retreive the number of death races this token has survived from the stat contract 
        IStats.RaptorStats memory _stats = stats.getStats(minterIndex, tokenId);

        uint64 numSurvived = _stats.deathRacesSurvived;
        require(numSurvived > 0, "ERR:NS");//NS => Not Stakable

        //Move the NFT to this contract
        require(minter.transferFrom(caller, address(this), tokenId),"ERR:OT");//OT => On Transfer

        //Store in DRSurvivals mapping
        DRSurvivals[minterIndex][tokenId] = numSurvived; 

        //Store stake details
        stakeData[minterIndex][tokenId] = StakeData({
            staker: caller,
            blockStakedOn: block.number,
            blockLastClaimed: block.number,
        });

        //Pull user details
        UserData storage data = userData[caller];

        //Store data
        data.minterIndexes.push(minterIndex);
        data.tokenIDs.push(tokenId);
    }

    function unstake(uint8 minterIndex, uint16 tokenId) external {
        //Check that the minter index is less than 2#
        require(minterIndex < 2, "ERR:MI");//MI => Minter Index

        //Get the staking data for the token & minter
        StakeData storage data = stakeData[minterIndex][tokenId];

        //Get the caller
        address caller = _msgSender();

        //Check that the caller is the staker
        require(caller == data.staker, "ERR:NS");//NS => Not Staker

        //Check that the block the token was staked is before now & not equal to zero
        require(data.blockStakedOn < block.number && data.blockStakedOn != 0 , "ERR:BS");//BS => Block Staked

        IERC721A minter;

        if(minterIndex == 0){
            minter = minter1;
        }else if(minterIndex == 1){
            minter = minter2;
        }

        //Check that the token is currently in this contract
        require(minter.ownerOf(tokenId) == address(this), "ERR:NS");//BS => Not Staked

        uint256 reward = getBlocksDueForRaptor(minterIndex, tokenId) * stakingRewardPerBlock;

        token.mint(caller, reward);

        delete data;

        minter.transferFrom(address(this), caller, tokenId);

    }

    function claim() external {

        //Get the address of the caller
        address caller = _msgSender();

        //Pull user details
        UserData storage data = userData[caller];
        
        //Check that the user has tokens staked
        require(data.tokenIds.length != 0, "ERR:NS");//NS => Nothing Staked

        //Calculate the reward 
        uint256 reward = getDueReward(caller);

        //Reset all block numbers to the current block
        resetTokenBlocks(caller);

        //Mint the reward tokens to the caller
        token.mint(caller, reward);

    }

    function resetTokenBlocks(address addr) internal {
        //Pull user details
        UserData storage data = userData[addr];

        //Pull tokenIds & minter indexes out of data
        uint8[] memory indexes = data.minterIndexes;
        uint16[] memory tokenIds = data.tokenIDs;

        //Iterater through the tokenIDs
        for(uint16 i = 0; i < tokenIds.length; ){

            //Set the tokens block that claiming last happened to now
            stakeData[indexes[i]][tokenIds[i]].blockLastClaimed = block.number;

            //Remove safe math wrapper
            unchecked{
                i++;
            }
        }
    }

    function getDueReward(address query) public view returns(uint256){

        //Pull user details
        UserData storage data = userData[query];

        //Define a variable that will store the number of blocks the user is due to be paid for
        uint256 totalBlocksWithMultiplier;

        //Iterate through tokenIds & minter indexes
        for(uint16 i = 0; i < data.tokenIds.length; ){

            //Calculate the total number of blocks with bonus multipliers
            totalBlocksWithMultiplier += getBlocksDueForRaptor(data.minterIndexes[i], data.tokenIDs[i]); 
            
            //Remove safe math check as we know the user will not be staking over 65,535 NFTs which is the 
            //highest number that a uint16 can hold, this helps reduce gas costs
            unchecked{
                i++;
            }
        }

        //Return the total due reward
        return totalBlocksWithMultiplier * stakingRewardPerBlock;
    }

    function getBlocksDueForRaptor(uint8 minterIndex, uint16 tokenId) internal returns(uint256){
        //Find the number of blocks the token has been staked for
        uint256 numOfBlocks = block.number - stakeData[minterIndex][tokenId].blockLastClaimed; 
        
        //Find the number of Death races that a token has survived
        uint64 numSurvived = DRSurvivals[minterIndex][tokenId];
        
        //Calculate the bonus multiplier for this token
        uint256 bonus = uint256((110 ** numSurvived) / (100 ** numSurvived));

        //Return the num Of Blocks times the boonus multiplier
        return numOfBlocks * bonus ;
    }


}