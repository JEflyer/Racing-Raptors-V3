//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//Import the interface for the stats contract
import "./interfaces/IStats.sol";

//Imported the context library for safe usage of msg.sender
import "@openzeppelin/contracts/utils/Context.sol";

//Import the interface for ERC20
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICoin.sol";

//Import the interface for ERC721A
import "./ERC721A/IERC721A.sol";

contract StrengthStaking is Context {

    error NotAuthorised();
    error IncorrectMinter();


    struct StepDetails {
        uint256 treasury;
        uint256 totalStrength;
        uint256 totalRewardThisStep;
        uint256 rewardPerSecond;
        uint256 timeStarted;
        uint256 timeEnded;
    }

    struct StakeDetails {
        address staker;
        uint256 stepStaked;
        uint256 stepLastClaimed;
        uint64 strength; 
    }

    struct UserData {
        uint8[] minterIndexes;
        uint16[] tokenIDs;
    }

    mapping(uint8 => mapping(uint16 => StakeDetails)) private stakeDetails;

    mapping(uint256 => StepDetails) private stepDetails;

    mapping(address => UserData) private userData;

    uint256 private stepId;

    uint256 private amountDue;

    //Stores the address of the admin of this contract
    address private admin;

    address private rate;

    //Stores an instance of an ERC20 interface
    ICoin private token;

    //Stores instances of the ERC721A contracts
    address[] private minters;

    //Stores an instance of the Stats interface
    IStats private stats;

    constructor(
        address[] memory _minters, address _token, address _stats, address _rate
    ){
        admin = _msgSender();

        minters = _minters;

        token = ICoin(_token);

        stats = IStats(_stats);

        rate = _rate;

        stepDetails[0].treasury = 100000 * 10 ** 18;
        
    }

    //This function is called everytime someone stakes or unstakes a NFT
    //The purpose is to keep a track of what blocks the total strength is for reward calculation
    function updateStep(uint256 totalStrength) internal {

        //Perform One SLOAD function
        uint256 step = stepId;

        StepDetails storage lastStep = stepDetails[step];
        StepDetails storage nextStep = stepDetails[++step];

        uint256 currentTime = block.timestamp;

        lastStep.timeEnded = currentTime - 1;

        nextStep.timeStarted = currentTime;
        
        uint256 rewardLastStep = lastStep.rewardPerSecond * (lastStep.timeEnded - lastStep.timeStarted);

        lastStep.totalRewardThisStep = rewardLastStep;

        nextStep.treasury = lastStep.treasury - rewardLastStep + amountDue;

        nextStep.rewardPerSecond = nextStep.treasury / 100000;

        nextStep.totalStrength = totalStrength;

        stepId = step;

        // //Store the final block for the last step
        // stepDetails[step].timeEnded = currentTime - 1;
        
        // //Increment the step before using & Assign new details
        // stepDetails[++step] = StepDetails({
        //     treasury: ,
        //     totalStrength: totalStrength,
        //     totalRewardThisStep: 0,
        //     rewardPerSecond: ,
        //     timeStarted: currentTime,
        //     timeEnded: block.timestamp
        // });

        // //Assign the new stepId to storage
        // stepId = step;
    }

    function stake(uint8 minterIndex, uint16 tokenId) external {
        //Check that minterIndex is less than 2
        require(minterIndex < 2, "ERR:MI");//MI => Minter Index

        //Get the address of the caller
        address caller = _msgSender();
        
        //Define an instance of the minter
        IERC721A minter;

        if( minterIndex > minters.length -1) {
            //Check on the stats contract if the minter index exists, returns with address if true
            address minterCheck = stats.checkMinterIndex(minterIndex);
            
            if(minterCheck == address(0)){
                revert IncorrectMinter();
            }else {
                minters.push(minterCheck);
                minter = IERC721A(minterCheck);
            }

        }else {
            minter = IERC721A(minters[minterIndex]);
        }

        //Check that the caller owns the token for minter index
        require(minter.ownerOf(tokenId) == caller,"ERR:NO");//NO => Not Owner
        
        //Check that the caller has given this contract approval over the token being staked
        require(minter.getApproved(tokenId) == address(this), "ERR:NA");//NA => Not Approved

        //Retreive the number of death races this token has survived from the stat contract 
        IStats.RaptorStats memory _stats = stats.getStats(minterIndex, tokenId);

        uint64 strength = _stats.strength;

        //Move the NFT to this contract
        minter.transferFrom(caller, address(this), tokenId);//OT => On Transfer

        uint256 step = stepId+1;

        //Update stake details for this token & minter
        stakeDetails[minterIndex][tokenId] = StakeDetails({
            staker: caller,
            strength: strength,
            stepStaked: step,
            stepLastClaimed: step
        }); 

        //Update the next step with the new total strength
        updateStep(stepDetails[stepId].totalStrength + strength);

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
        IERC721A minter;

        if( minterIndex > minters.length -1) {
            //Check on the stats contract if the minter index exists, returns with address if true
            address minterCheck = stats.checkMinterIndex(minterIndex);
            
            if(minterCheck == address(0)){
                revert IncorrectMinter();
            }else {
                minters.push(minterCheck);
                minter = IERC721A(minterCheck);
            }

        }else {
            minter = IERC721A(minters[minterIndex]);
        }

        //Check that the caller owns the token for minter index
        require(minter.ownerOf(tokenId) == address(this),"ERR:NO");//NO => Not Owner
        
        //Pull the struct into the function
        StakeDetails storage details = stakeDetails[minterIndex][tokenId];

        //Check that the staker is the caller
        require(details.staker == caller, "ERR:NS");//NS => Not Staker

        //Move the NFT from this contract to the staker
        minter.transferFrom(address(this), caller, tokenId);//OT => On Transfer

        //Calculate the reward
        uint256 reward = getDueRewardForToken(minterIndex, tokenId);
        
        //Pay Staker
        token.mint(reward, caller);

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

        //Delete stakeDetails
        delete details.staker;
        delete details.strength;
        delete details.stepLastClaimed;
        delete details.stepStaked;

        //Emit Event
    }

    function claim(uint8 minterIndex, uint16 tokenId) external {
        address caller = _msgSender();

        StakeDetails storage details = stakeDetails[minterIndex][tokenId];

        if(details.staker != caller) revert NotAuthorised();

        uint256 reward = getDueRewardForToken(minterIndex,tokenId);

        require(reward > 0, "ERR:NR");//NR => No Reward

        updateStep(stepDetails[stepId].totalStrength);

        details.stepLastClaimed = stepId;

        token.mint(reward, caller);

        //Emit Event
    }

    // function resetSteps(address addr) internal {
    //     //Pull user details
    //     UserData storage data = userData[addr];

    //     uint8[] storage minterIndexes = data.minterIndexes; 
    //     uint16[] storage tokenIds = data.tokenIDs;

    //     uint256 currentStep = stepId + 1;

    //     for(uint16 i = 0; i< tokenIds.length;) {

    //         stakeDetails[minterIndexes[i]][tokenIds[i]].stepLastClaimed = currentStep;

    //         unchecked{
    //             i++;
    //         }
    //     }
    // }


    function getDueRewardForToken(uint8 minterIndex, uint16 tokenId) internal view returns(uint256){

        StakeDetails memory details = stakeDetails[minterIndex][tokenId];

        uint256 step = details.stepLastClaimed == 0 ? details.stepStaked : details.stepLastClaimed;

        uint256 total = 0;

        StepDetails memory deetz;

        for(; step < stepId;){

            deetz = stepDetails[step];

            total += (details.strength * deetz.totalRewardThisStep) / deetz.totalStrength;

            unchecked{
                step++;
            }
        }

        deetz = stepDetails[step + 1];

        total += (details.strength * deetz.rewardPerSecond) / deetz.totalStrength * (block.timestamp - deetz.timeStarted);

    }

}