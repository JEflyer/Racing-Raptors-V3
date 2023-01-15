//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//Imported the ILPDepositor interface depositing USD
import "./interfaces/ILpDepositor.sol";

//Imported the context library for safe usage of msg.sender
import "@openzeppelin/contracts/utils/Context.sol";

//Import the interface for ERC20
import "./interfaces/ICoin.sol";

//Import the interface for the stats contract
import "./interfaces/IStats.sol";

//Import the interface for ERC721A
import "./ERC721A/IERC721A.sol";

contract StrengthStaking is Context {

    error NotAuthorised();
    error IncorrectMinter();
    error AmountApproved();
    error NullAddress();


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

    address private usd;

    ILpDepositor private lpDepositor;

    //Stores an instance of an ERC20 interface
    ICoin private token;

    //Stores instances of the ERC721A contracts
    IERC721A[] private minters;

    //Stores an instance of the Stats interface
    IStats private stats;

    constructor(
        IERC721A[] memory _minters, address _token, address _stats, address _rate, address _usd, address _lpDepositor
    ){
        for(uint256 i = 0; i < _minters.length;){

            if(address(_minters[i]) == address(0)) revert NullAddress();

            unchecked{
                i++;
            }
        }

        if(
            _token == address(0) ||
            _stats == address(0) ||
            _rate == address(0) ||
            _usd == address(0) ||
            _lpDepositor == address(0)
        ) revert NullAddress();

        admin = _msgSender();

        minters = _minters;

        token = ICoin(_token);

        stats = IStats(_stats);

        rate = _rate;

        lpDepositor = ILpDepositor(_lpDepositor);

        stepDetails[0].treasury = 100000 * 10 ** 18;

        usd = _usd;
        
    }

    //This function is called everytime someone stakes or unstakes a NFT
    //The purpose is to keep a track of what blocks the total strength is for reward calculation
    function updateStep(uint256 totalStrength) private {

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
    }

    function stake(uint8 minterIndex, uint16 tokenId) external {

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
                minters.push(IERC721A(minterCheck));
                minter = IERC721A(minterCheck);
            }

        }else {
            minter = minters[minterIndex];
        }

        //Check that the caller owns the token for minter index
        require(minter.ownerOf(tokenId) == caller,"ERR:NO");//NO => Not Owner
        
        //Check that the caller has given this contract approval over the token being staked
        require(minter.getApproved(tokenId) == address(this), "ERR:NA");//NA => Not Approved


        uint256 amountApproved = IERC20(usd).allowance(caller,address(this));

        if(amountApproved < 1000000) revert AmountApproved();

        IERC20(usd).transferFrom(caller,address(lpDepositor),1000000);

        if(lpDepositor.check()) lpDepositor.update();

        //Retreive the number of death races this token has survived from the stat contract 
        IStats.RaptorStats memory _stats = stats.getStats(minterIndex, tokenId);

        uint64 strength = _stats.strength;

        //Move the NFT to this contract
        minter.transferFrom(caller, address(this), tokenId);//OT => On Transfer

        uint256 step = ++stepId;

        //Update stake details for this token & minter
        stakeDetails[minterIndex][tokenId] = StakeDetails({
            staker: caller,
            strength: strength,
            stepStaked: step,
            stepLastClaimed: step
        }); 

        //Update the next step with the new total strength
        updateStep(stepDetails[step - 1].totalStrength + strength);

        //Pull user details
        UserData storage data = userData[caller];

        //Store data
        data.minterIndexes.push(minterIndex);
        data.tokenIDs.push(tokenId);

        //Emit Event
    }

    function unstake(uint8 minterIndex, uint16 tokenId) external {

        //Get the address of the caller
        address caller = _msgSender();
        
        //Declare an instance of the minter
        IERC721A minter;

        if( minterIndex > minters.length -1) {
            //Check on the stats contract if the minter index exists, returns with address if true
            // address minterCheck = stats.checkMinterIndex(minterIndex);
            
            // if(minterCheck == address(0)){
                revert IncorrectMinter();
            // }else {
            //     minters.push(IERC721A(minterCheck));
            //     minter = IERC721A(minterCheck);
            // }

        }else {
            minter = minters[minterIndex];
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


    function getDueRewardForToken(uint8 minterIndex, uint16 tokenId) public view returns(uint256){

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

        total += ((details.strength * deetz.rewardPerSecond) / deetz.totalStrength) * (block.timestamp - deetz.timeStarted);

        return total;

    }

}