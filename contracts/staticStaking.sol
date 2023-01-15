//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//Import the interface for the stats contract
import "./interfaces/IStats.sol";

//Imported the context library for safe usage of msg.sender
import "@openzeppelin/contracts/utils/Context.sol";

//Import the interface for ERC20
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ICoin.sol";
import "./interfaces/IRate.sol";
import "./interfaces/ILpDepositor.sol";

//Import the interface for ERC721A
import "./ERC721A/IERC721A.sol";


contract StaticStaking is Context{

    error NullAddress();
    error NullValue();
    error IncorrectMinter();
    error NotOwnerOfToken();
    error NotApproved();
    error BlockStaked();
    error NoDeathRacesSurvived();
    error NotOwnedByThisContract();
    error NothingStaked();
    error FailedUpdate();
    error NothingOwed();

    //Stores an instance of an ERC20 interface
    address private token;

    //Stores an instance of the rate contract for retrieving the share of burned tokens
    address private rate;
    
    //Stores the address of the USD token taken as a fee
    address private usd;

    ILpDepositor private depositor;

    //Stores instances of the ERC721A contracts
    address[] private minters;

    //Stores an instance of the Stats interface
    IStats private stats;

    uint256 private numStaked;

    //This is data specific to the token 
    struct StakeData {
        address staker;
        uint256 stepStakedOn;
        uint256 stepLastClaimed; 
        uint64 numOfDeathRacesSurvived;
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

    struct Step {
        uint256 treasury;
        uint256 rewardPerSecond;
        uint256 timeStepStarted;
        uint256 rewardGivenThisStep;
        uint256 totalDeathRacesSurvived;
    }

    mapping(uint256 => Step) private stepDetails;

    uint256 public stepID;

    constructor(address[] memory _minters, address _token, address _stats, address _rate, address _usd, address _depositor){

        for(uint256 i = 0; i < _minters.length; ){

            if(_minters[i] == address(0)) revert NullAddress();

            unchecked{
                i++;
            }
        }

        if(
            _token == address(0) ||
            _stats == address(0) || 
            _usd == address(0) || 
            _depositor == address(0) || 
            _rate == address(0)
        ) revert NullAddress();


        //Build instance of an ERC20 interface
        token = _token;

        usd = _usd;

        depositor = ILpDepositor( _depositor);

        //Set the minters
        minters = _minters;

        //Build an instance of the Stats contract interface
        stats = IStats(_stats);

        rate = _rate;

        stepDetails[0].treasury = 100000 * 10 ** 18;
        stepDetails[0].rewardPerSecond = 0;
        stepDetails[0].timeStepStarted = block.timestamp;

        numStaked = 0;

    }

    function stake(uint16 tokenId, uint8 minterIndex) external {
        
        //Get the address of the caller
        address caller = _msgSender();

        //Check that the user has approved this contract to spend 1 USD
        uint256 amountApproved = IERC20(usd).allowance(caller,address(this));

        if(amountApproved < 1000000) revert AmountApproved();
        
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
        if(minter.ownerOf(tokenId) != caller) revert NotOwnerOfToken();//NO => Not Owner
        
        //Check that the caller has given this contract approval over the token being staked
        if(minter.getApproved(tokenId) != address(this)) revert NotApproved();//NA => Not Approved

        //Retreive the number of death races this token has survived from the stat contract 
        IStats.RaptorStats memory _stats = stats.getStats(minterIndex, tokenId);

        uint64 numSurvived = _stats.deathRacesSurvived;
        if (numSurvived == 0) revert NoDeathRacesSurvived();//NS => Not Stakable

        IERC20(usd).transferFrom(caller,address(depositor),1000000);

        if(depositor.check()) depositor.update();

        //Move the NFT to this contract
        minter.transferFrom(caller, address(this), tokenId);//OT => On Transfer

        //Store stake details
        stakeData[minterIndex][tokenId] = StakeData({
            staker: caller,
            stepStakedOn: stepID+1,
            stepLastClaimed: stepID+1,
            numOfDeathRacesSurvived: numSurvived
        });

        //Pull user details
        UserData storage data = userData[caller];

        //Store data
        data.minterIndexes.push(minterIndex);
        data.tokenIDs.push(tokenId);

        numStaked += 1;

        //Update step details
        _update(numSurvived,true);
    }

    function _update(uint64 racesSurvived, bool adding) private {
        Step storage lastStep = stepDetails[stepID];
        Step storage nextStep = stepDetails[++stepID];

        
        uint256 rewardThisStep = lastStep.rewardPerSecond * (block.timestamp - lastStep.timeStepStarted);

        
        lastStep.rewardGivenThisStep = rewardThisStep;
        
        //TODO - Add amountDue given from rate contract at this point
        nextStep.treasury = lastStep.treasury - rewardThisStep;
        
        
        nextStep.rewardPerSecond = nextStep.treasury / 100000;
        
        
        nextStep.timeStepStarted = block.timestamp;
        
        
        if(adding && racesSurvived > 0){
            nextStep.totalDeathRacesSurvived = lastStep.totalDeathRacesSurvived + racesSurvived;
        } else if (!adding && racesSurvived > 0){
            nextStep.totalDeathRacesSurvived = lastStep.totalDeathRacesSurvived - racesSurvived;
        }

        if(!IRate(rate).acceptUpdateFromDRS(numStaked)) revert FailedUpdate();

    }

    function unstake(uint16 tokenId, uint8 minterIndex) external {

        //Get the staking data for the token & minter
        StakeData storage data = stakeData[minterIndex][tokenId];

        //Get the caller
        address caller = _msgSender();

        //Define an instance of the minter
        IERC721A minter;

        if( minterIndex > minters.length -1) {
            // //Check on the stats contract if the minter index exists, returns with address if true
            // address minterCheck = stats.checkMinterIndex(minterIndex);
            
            // if(minterCheck == address(0)){
            //     revert IncorrectMinter();
            // }else {
            //     minters.push(minterCheck);
            //     minter = IERC721A(minterCheck);
            // }
            revert IncorrectMinter();

        }else {
            minter = IERC721A(minters[minterIndex]);
        }

        //Check that the caller is the staker
        if (caller != data.staker) revert NotOwnerOfToken();//NS => Not Staker

        //Check that the block the token was staked is before now & not equal to zero
        if (data.stepStakedOn == stepID || data.stepStakedOn == 0) revert BlockStaked();


        //Check that the token is currently in this contract
        if (minter.ownerOf(tokenId) != address(this)) revert NotOwnedByThisContract();

        uint256 reward = getRewardDueForRaptor(minterIndex, tokenId);

        ICoin(token).mint(reward, caller);

        numStaked -= 1;

        _update(data.numOfDeathRacesSurvived,false);


        delete data.staker;
        delete data.stepStakedOn;
        delete data.stepLastClaimed;
        delete data.numOfDeathRacesSurvived;

        minter.transferFrom(address(this), caller, tokenId);

        //Remove the token from the user data  
        UserData storage data = userData[caller];

        if(data.tokenIDs.length == 1){
            delete data.tokenIDs;
            delete data.minterIndexes;
        }else{
            for(uint256 i = 0; i < data.tokenIDs.length;){

                if(
                    data.tokenIDs[i] == tokenId 
                    &&
                    data.minterIndexes[i] == minterIndex
                ){
                    data.tokenIDs[i] = data.tokenIDs[data.tokenIDs.length-1];
                    data.minterIndexes[i] = data.minterIndexes[data.minterIndexes.length-1];
                    data.minterIndexes.pop();
                    data.tokenIDs.pop();
                }

                unchecked {
                    i++;
                }
            }
        }


    }

    function getRewardDueForRaptor(uint8 minterIndex, uint16 tokenID) public view returns(uint256) {

        //Initialize the total
        uint256 total = 0;

        //Retrieve the stake data for the token
        StakeData memory details = stakeData[minterIndex][tokenId];

        uint256 step = details.stepLastClaimed == 0 ? details.stepStakedOn : details.stepLastClaimed;

        if (step == 0) return 0;

        //We computate all completed steps minus the current step 
        for(uint256 j = step; j < stepID; ){

            //Find the tokens share on this step
            total += (details.numOfDeathRacesSurvived * stepDetails[j].rewardGivenThisStep) / stepDetails[j].totalDeathRacesSurvived;

            unchecked {
                j++;
            }
        }

        //Now we compute the current step
        total += ((details.numOfDeathRacesSurvived * stepDetails[stepID].rewardPerSecond) / stepDetails[stepID].totalDeathRacesSurvived) * (block.timestamp - stepDetails[stepID].timeStepStarted);

        return total;

    } 

    function claim(uint8 minterIndex, uint16 tokenId) external {

        //Get the address of the caller
        address caller = _msgSender();

        StakeData storage data = stakeData[minterIndex][tokenId]; 

        if(caller != data.staker) revert NotOwnerOfToken();

        if(data.stepStakedOn == 0) revert NotStaked();
        if(data.stepStakedOn == stepID) revert StakedThisStep();

        //Calculate the reward 
        uint256 reward = getRewardDueForRaptor(minterIndex,tokenId);

        if(reward == 0) revert NothingOwed();

        data.stepLastClaimed = stepID + 1;

        //Mint the reward tokens to the caller
        ICoin(token).mint(reward, caller);
        
        _update(0,false);

    }


}