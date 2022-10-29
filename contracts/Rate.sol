//SPDX-License-Identifier: GLWTPL
pragma solidity 0.8.15;

import "./interfaces/IStake.sol";

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract Rate is KeeperCompatibleInterface{

    error NotAuthorised();
    error NullAddress();
    error AlreadyInitialized();
    error NothingBurned();
    error FailedUpdate0();
    error FailedUpdate1();
    error FailedUpdate2();
    error FailedUpdate3();
    
    address private initializer;


    address private viewerBetting;
    address[4] private minters; 
    address[3] private burners; 


    uint256 private totalBurned;
    uint256 private totalMinted;
    uint256 private currentStepID;


    //RCV => RaptorCoinValue
    uint256 private latest_DRS_RCV;//DRS => Death Race Staking
    uint256 private latest_SS_RCV;//SS => Strength Staking
    uint256 private latest_LPS_RCV;//LPS => Liquidity Pair Staking
    uint256 private latest_RCS_RCV;//RCS => Raptor Coin Staking

    uint256 private latest_average_raptor_price;

    uint256 private amountBurnedSinceLastCalculation;

    struct StepInfo {
        uint256 totalBurnedThisStep;
        uint256 DRS_RCV;
        uint256 SS_RCV;
        uint256 LPS_RCV;
        uint256 RCS_RCV;
        uint256 averageRaptorPrice;
    }

    mapping(uint256 => StepInfo) private stepDetails;

    bool private initialized;

    constructor(){
        initializer = msg.sender;
    }

    function initialize(address[4] calldata _minters, address[3] calldata _burners) external {
        if(msg.sender != initializer) revert NotAuthorised();
        if(initialized) revert AlreadyInitialized();
        if(
            _minters[0] == address(0) ||
            _minters[1] == address(0) ||
            _minters[2] == address(0) ||
            _minters[3] == address(0) ||
            _burners[0] == address(0) ||
            _burners[1] == address(0) ||
            _burners[2] == address(0)         
        ) revert NullAddress();

        minters = _minters;
        burners = _burners;
    }

    modifier isMinter(uint256 index){
        if(msg.sender != minters[index]) revert NotAuthorised();
        _;
    }

    modifier isBurner(uint256 index){
        if(msg.sender != burners[index]) revert NotAuthorised();
        _;
    }

    function acceptUpdateFromDRS(uint256 numRaptor) external isMinter(0) returns(bool){
        latest_DRS_RCV = numRaptor * latest_average_raptor_price;
        return true;
    }

    function acceptUpdateFromSS(uint256 numRaptor) external isMinter(1) returns(bool){
        latest_SS_RCV = numRaptor * latest_average_raptor_price;
        return true;
    }

    function acceptUpdateFromLPS(uint256 numRaptor) external isMinter(2) returns(bool){
        latest_LPS_RCV = numRaptor;
        return true;
    }

    function acceptUpdateFromRCS(uint256 numRaptor) external isMinter(3) returns(bool){
        latest_RCS_RCV = numRaptor;
        return true;
    }

    function acceptUpdateFromGame(uint256 numBurned) external isBurner(0) returns(bool){
        totalBurned += numBurned;
        amountBurnedSinceLastCalculation += numBurned;
        return true;
    }

    function acceptUpdateFromRCT(uint256 numBurned) external isBurner(1) returns(bool){
        totalBurned += numBurned;
        amountBurnedSinceLastCalculation += numBurned;
        return true;
    }

    function acceptUpdateFromMarketplace(uint256 numBurned,uint256 averagePrice) external isBurner(2) returns(bool){
        totalBurned += numBurned;
        amountBurnedSinceLastCalculation += numBurned;
        latest_average_raptor_price = averagePrice;
        return true;
    }

    function acceptUpdateFromVB(uint256 numBurned, uint256 numMinted) external returns(bool){
        //Check that caller is viewer betting contract
        if(msg.sender != viewerBetting) revert NotAuthorised();
        totalMinted += numMinted;
        totalBurned += numBurned;
        amountBurnedSinceLastCalculation += numBurned;
        return true;
    }

    function retrieveDetails() external view returns(uint256,uint256,uint256){
        return(totalBurned,totalMinted,currentStepID);
    }

    function queryStep(uint256 stepID) external view returns(StepInfo memory){
        return stepDetails[stepID];
    }


    function performUpkeep(bytes calldata data) external override {
        uint256 id = currentStepID;
        
        StepInfo storage nextStep = stepDetails[++id];  

        uint256 toShare = amountBurnedSinceLastCalculation * 90 / 100;

        if(toShare == 0){
            revert NothingBurned();
        }else {
            
            uint256 _latest_DRS_RCV = latest_DRS_RCV;
            uint256 _latest_SS_RCV = latest_SS_RCV;
            uint256 _latest_LPS_RCV = latest_LPS_RCV;
            uint256 _latest_RCS_RCV = latest_RCS_RCV;

            nextStep.totalBurnedThisStep = toShare;
            nextStep.DRS_RCV = _latest_DRS_RCV;
            nextStep.SS_RCV = _latest_SS_RCV;
            nextStep.LPS_RCV = _latest_LPS_RCV;
            nextStep.RCS_RCV = _latest_RCS_RCV;
            nextStep.averageRaptorPrice = latest_average_raptor_price;

            uint256 totalRCV = latest_RCS_RCV + latest_LPS_RCV + latest_SS_RCV + latest_DRS_RCV;

            amountBurnedSinceLastCalculation = 0;

            address[4] memory _minters = minters;

            // amountDue[_minters[0]] += (_latest_DRS_RCV * toShare) / totalRCV;
            // amountDue[_minters[1]] += (_latest_SS_RCV * toShare) / totalRCV;
            // amountDue[_minters[2]] += (_latest_LPS_RCV * toShare) / totalRCV;
            // amountDue[_minters[3]] = (_latest_RCS_RCV * toShare) / totalRCV;

            if(!IStake(_minters[0]).Update((_latest_DRS_RCV * toShare) / totalRCV)) revert FailedUpdate0();
            if(!IStake(_minters[1]).Update((_latest_SS_RCV * toShare) / totalRCV)) revert FailedUpdate1();
            if(!IStake(_minters[2]).Update((_latest_LPS_RCV * toShare) / totalRCV)) revert FailedUpdate2();
            if(!IStake(_minters[3]).Update((_latest_RCS_RCV * toShare) / totalRCV)) revert FailedUpdate3();

            currentStepID = id;
        }
    }
    function checkUpkeep(bytes calldata checkData) external override returns (bool upkeepNeeded, bytes memory performData){}
}
