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

contract StrengthStaking is Context {


    struct StepDetails {
        uint256 totalStrength;
        uint64 blockUpdated;
        uint64 blockUntil;
    }

    struct StakeDetails {
        address staker;
        uint64 strength; 
        uint64 blockStaked;
        uint64 blockLastClaimed;
    }

    struct UserData {
        uint8[] minterIndexes;
        uint16[] tokenIDs;
    }

    mapping(uint8 => mapping(uint16 => StakeDetails)) private stakeDetails;

    mapping(uint256 => StepDetails) private stepDetails;

    mapping(address => UserData) private userData;

    uint256 private stepId;

    uint256 private totalBlockReward;

    //Stores the address of the admin of this contract
    address private admin;

    //Stores an instance of an ERC20 interface
    IERC20 private token;

    //Stores instances of the ERC721A interface
    IERC721A private minter1;
    IERC721A private minter2;

    //Stores an instance of the Stats interface
    IStats private stats;

    constructor(
        address _minter1, address _minter2, address _token, address _stats, uint256 _totalRewardPerBlock
    ){
        admin = _msgSender();

        minter1 = IERC721A(_minter1);
        minter2 = IERC721A(_minter2);

        token = IERC20(_token);

        stats = IStats(_stats);

        totalBlockReward = _totalRewardPerBlock;
        
    }

    //This function is called everytime someone stakes or unstakes a NFT
    //The purpose is to keep a track of what blocks the total strength is for reward calculation
    function updateStep(uint256 totalStrength) internal {
        
        //Perform One SLOAD function
        uint256 step = stepId;

        //Perform One SLOAD function
        uint64 currentBlock = block.number;

        //Store the final block for the last step
        stepDetails[step].blockUntil = currentBlock-1;
        
        //Increment the step before using & Assign new details
        stepDetails[++step] = StepDetails({
            totalStrength: totalStrength,
            blockUpdated: currentBlock
        });

        //Assign the new stepId to storage
        stepId = step;
    }

    function stake(uint8 minterIndex, uint16 tokenId) external {
        //Check that minterIndex is less than 2
        require(minterIndex < 2, "ERR:MI");//MI => Minter Index

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

        uint64 strength = _stats.strength;

        //Move the NFT to this contract
        require(minter.transferFrom(caller, address(this), tokenId),"ERR:OT");//OT => On Transfer

        //Update stake details for this token & minter
        stakeDetails[minterIndex][tokenId] = StakeDetails({
            staker: caller,
            strength: strength,
            blockStaked: uint64(block.number),
            blockLastClaimed: uint64(block.number)
        }); 

        //Update the next step with the new total strength
        updateStep(stepDetails[stepId] + strength);

        //Pull user details
        UserData storage data = userData[caller];

        //Store data
        data.minterIndexes.push(minterIndex);
        data.tokenIDs.push(tokenId);

        //Emit Event
    }

    function unstake(uint8 minterIndex, uint16 tokenId) external {
        //Check that minterIndex is less than 2
        require(minterIndex < 2, "ERR:MI");//MI => Minter Index

        //Get the address of the caller
        address caller = _msgSender();
        
        //Declare an instance of the minter
        IERC721A memory minter;

        //Assign the minter to memory
        if(minterIndex == 0){
            minter = minter1;
        }else if(minterIndex == 1){
            minter = minter2;
        }  

        //Check that the caller owns the token for minter index
        require(minter.ownerOf(tokenId) == address(this),"ERR:NO");//NO => Not Owner
        
        //Pull the struct into the function
        StakeDetails storage details = stakeDetails[minterIndex][tokenId];

        //Check that the staker is the caller
        require(details.staker == caller, "ERR:NS");//NS => Not Staker

        //Move the NFT from this contract to the staker
        require(minter.transferFrom(address(this), caller, tokenId),"ERR:OT");//OT => On Transfer

        //Calculate the reward
        uint256 reward = getDueRewardForToken(minterIndex, tokenId)
        
        //Pay Staker
        token.mint(caller, reward);

        //Update the next step with the new total strength
        updateStep(stepDetails[stepId].totalStrength - details.strength);

        //Pull user details
        UserData storage data = userData[caller];

        uint8[] storage minterIndexes = data.minterIndexes; 
        uint16[] storage tokenIds = data.tokenIDs; 

        //Remove data
        for(uint16 i = 0 ; i < tokenIds.length; ){

            if(
                minterIndexes[i] == minterIndex
                &&
                tokenIds[i] == tokenId
            ){
                minterIndexes[i] = minterIndexes[minterIndexes.length-1];
                minterIndexes.pop();
                
                tokenIds[i] = tokenIds[tokenIds.length-1];
                tokenIds.pop();
            }

            unchecked{
                i++;
            }
        }

        //Emit Event
    }

    function claim() external {

    }

    function getDueRewardForUser(address query) public view returns(uint256){

    } 

    function getDueRewardForToken(uint8 minterIndex, uint16 tokenId) internal view returns(uint256){

    }

}