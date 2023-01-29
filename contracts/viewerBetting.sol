//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICoin.sol";

import "./interfaces/IStats.sol";
import "./interfaces/IVerify.sol";

import "./structs/Results.sol";

contract ViewerBetting is Context{

    error NullAddress();
    error NotAdmin();
    error NotGame();
    error NotAuthorised();

    address private admin;
    address private game;
    address private sigVerifier;

    IStats private stats;

    ICoin private token;

    struct RaptorDetails {
        uint64 speed;
        uint16 tokenId;
        uint8 minterIndex;
    }

    //toWin => evaluate rewward based on speed
    //toFight => 3x reward if correct
    //toWinFight => 6x reward if correct
    //toPlaceTop3 => evaluate reward based on speed
    enum BetType{
        toWin,
        tofight,
        towinFight,
        toPlaceTop3
    }

    struct BetterDetails {
        uint16 tokenId;
        uint8 minterIndex;
        uint256 valueBet;
        BetType betType;
    }

    struct BetDetails {
        //Raptors are sorted & stored by how fast they are index 0 - 7
        mapping(uint8 => RaptorDetails) sortedRaptors;
        //bool tracking whether game is active or not
        bool active;
        //Keep an array of better addresses to iterate through
        address[] betters;
        //Store mapping of better to better details
        mapping(address => BetterDetails) betterDetails;
    }

    BetDetails public betDetails;

    constructor(address _game,address _stats, address _sigVerifier){
        if(_game == address(0)) revert NullAddress();
        if(_sigVerifier == address(0)) revert NullAddress();
        if(_stats == address(0)) revert NullAddress();
        game = _game;
        stats = IStats(_stats);
        admin = _msgSender();
        sigVerifier = _sigVerifier;
    }

    modifier onlyGame {
        if(msg.sender != game) revert NotGame();
        _;
    }

    modifier onlyAdmin{
        if(_msgSender() != admin) revert NotAdmin();
        _;
    }
    
    function setGame(address _game) external onlyAdmin {
        if(_game == address(0)) revert NullAddress();
        game = _game;
    }

    function setAdmin(address _new) external onlyAdmin {
        if(_new == address(0)) revert NullAddress();
        admin = _new;
    } 

    function relinquishControl() external onlyAdmin {
        delete admin;
    }

    function openBetting(uint16[] memory _raptors, uint8[] memory _minterIndexes) external onlyGame {

        uint64[] memory speed;

        uint8[] memory fastestSpeedIndexes; //speed from max to min

        //we want the array of indexes the highest speeds into a new array
        for(uint8 i = 0;  i < _raptors.length;){

            speed[i] = stats.getSpeed(_minterIndexes[i], _raptors[i]);
            fastestSpeedIndexes[i] = i;
            unchecked{
                i++;
            }
        }

        for(uint8 i = 0; i<speed.length-1;){
            if(speed[i] < speed[i+1]){
                uint64 temp = speed[i];
                speed[i] = speed[i+1];
                speed[i+1] = temp;

                uint8 tempIndex = fastestSpeedIndexes[i];
                fastestSpeedIndexes[i] = fastestSpeedIndexes[i+1];
                fastestSpeedIndexes[i+1] = tempIndex;

                if(i > 0){
                    i-=1;
                    continue;
                }
            }
            unchecked{
                i++;
            }
        }
        //0  2  1  3  4
        //      

        BetDetails storage details = betDetails;

        for(uint8 i = 0; i< speed.length;){

            details.sortedRaptors[i] = RaptorDetails({
                speed: speed[fastestSpeedIndexes[i]],
                tokenId: _raptors[fastestSpeedIndexes[i]],
                minterIndex: _minterIndexes[fastestSpeedIndexes[i]]
            });

            unchecked{
                i++;
            }
        }
        details.active = true;
    } 

    function closeBetting(Results memory _results) external onlyGame {
        BetDetails storage details = betDetails;
        details.active = false;

        (address[] memory addresses, uint256[] memory amounts) = getPayouts(_results);

        if(addresses.length != 0){
            for(uint256 i = 0; i < addresses.length; ){

                token.mint(amounts[i],addresses[i]);

                unchecked{
                    i++;
                }
            }
        }

        for(uint256 i = 0; i < 8;){

            delete details.sortedRaptors[uint8(i)];

            unchecked{
                i++;
            }
        }

        for(uint256 i = 0; i < details.betters.length;){
            delete details.betterDetails[details.betters[i]];
        }

        delete details.betters;
    }


//    struct BetDetails {
//         //Raptors are sorted & stored by how fast they are index 0 - 7
//         mapping(uint8 => RaptorDetails) sortedRaptors;
//         //bool tracking whether game is active or not
//         bool active;
//         //Keep an array of better addresses to iterate through
//         address[] betters;
//         //Store mapping of better to better details
//         mapping(address => BetterDetails) betterDetails;
//     }

    //potential outcomes
    //        |speed|
    //raptor 1 - 10 - fight or winner
    //raptor 2 - 8 - fight or top 3 or winner
    //raptor 3 - 8 - fight or top 3 or winner
    //raptor 4 - 4 - fight or guaranteed loss
    //raptor 5 - 3 - fight or guaranteed loss
    //raptor 6 - 2 - fight or guaranteed loss
    //raptor 7 - 6  - fight or guaranteed loss/potential top3
    //raptor 8 - 5 - fight or guaranteed loss/potential top3

    //winning to fight bet 3x reward for any raptor

    //winning to win fight bet 6x reward for any raptor

    //winning to win bet for fastest raptor - 10% reward on top of your original bet
    //winning to win for second fastest raptor -  15% reward on top of your original bet
    //winning to win for third fastest raptor -  20% reward on top of your original bet
    //winning to win for fourth fastest raptor - 


    //winning top 3 bet for fastest raptor - 10% reward on top of your original bet
    //winning top 3 for second fastest raptor -  10% reward on top of your original bet
    //winning top 3 for third fastest raptor -  10% reward on top of your original bet
    //winning top 3 for fourth fastest raptor -  20% reward on top of your original bet
    //winning top 3 for fifth fastest raptor -  100% reward on top of your original bet
    //winning top 3 for sixth fastest raptor -  

    function getPayouts(Results memory _results) private view returns(address[] memory addresses, uint256[] memory payouts){
        BetDetails storage details = betDetails;

        address[] memory betters = details.betters;

        for(uint64 i = 0; i<details.betters.length; ){

            uint256 payout = check(details.betterDetails[betters[i]], _results);
            if(payout > 0){
                addresses[addresses.length] = betters[i];
                payouts[payouts.length] = payout;
            }
            unchecked{
                i++;
            }
        }

    }

    function check (BetterDetails memory details,Results memory _results) private view returns(uint256){
        if(uint(details.betType) == 0){// To Win
            if(
                _results.top3IDs[0] == details.tokenId 
                && _results.top3MinterIndexes[0] == details.minterIndex
            ){
                return details.valueBet * getWinningMultiplier(details.tokenId, details.minterIndex) / 100;
            }else {
                return 0;
            }

        }else if(uint(details.betType) == 1){// To Fight
            if(
                _results.fighterIDs[0] == details.tokenId
                && _results.fighterMinterIndexes[0] == details.minterIndex
            ){
                return details.valueBet * 3;
            }else if(
                _results.fighterIDs[1] == details.tokenId
                && _results.fighterMinterIndexes[1] == details.minterIndex
            ){
                return details.valueBet * 3;
            }else {
                return 0;
            }
        }else if(uint(details.betType) == 2){// To Win Fight
            
            if(
                _results.fighterIDs[0] == details.tokenId
                && _results.fighterMinterIndexes[0] == details.minterIndex
            ){
                return details.valueBet * 6;
            }else {
                return 0;
            }

        }else if(uint(details.betType) == 3){// To Finish Top 3

            for(uint8 i = 0; i < _results.top3IDs.length; ){

                if(
                    _results.top3IDs[i] == details.tokenId
                    && _results.top3MinterIndexes[i] == details.minterIndex
                ){
                    return details.valueBet * getTop3WinningModifier(details.tokenId,details.minterIndex) / 100;
                }

                unchecked{
                    i++;
                }
            }
            return 0;    
        }
        return 0;    
    }

    function getWinningMultiplier(uint16 tokenId, uint8 index) private view returns(uint256){
        BetDetails storage details = betDetails;


        for(uint8 i = 0 ; i < 8;){

            if(
                details.sortedRaptors[i].tokenId == tokenId 
                &&
                details.sortedRaptors[i].minterIndex == index
            ){
                if(i == 0){
                    return 110;
                }else if(i == 1){
                    return 115;
                }else if(i == 2){
                    return 120;
                }else if(i == 3){
                    return 135;
                }else if(i == 4){
                    return 150;
                }else if(i == 5){
                    return 170;
                }else if(i == 6){
                    return 185;
                }else if(i == 7){
                    return 200;
                }
            }

            unchecked{ 
                i++;
            }
        }

        return 0;

    }

    function getTop3WinningModifier(uint16 tokenID, uint8 index) private view returns(uint256){
        BetDetails storage details = betDetails;

        for(uint8 i = 0 ; i < 8;){

            if(
                details.sortedRaptors[i].tokenId == tokenID 
                &&
                details.sortedRaptors[i].minterIndex == index
            ){
                if(i < 3){
                    return 110;
                }else if(i == 3){
                    return 120;
                }else if(i == 4){
                    return 130;
                }else if(i == 5){
                    return 140;
                }else if(i == 6){
                    return 150;
                }else if(i == 7){
                    return 160;
                }
            }

            unchecked{ 
                i++;
            }
        }

        return 0;
    }

    function bet(uint16 _raptor, uint8 _minterIndex, BetType _bet, uint256 _amount, uint8 v, bytes32 r, bytes32 s) external {

        if(!IVerify(sigVerifier).verifySignature(v,r,s,msg.sender)) revert NotAuthorised();

        BetDetails storage details = betDetails;
        require(details.active, "ERR:NO");//NO => Not Open

        address caller = msg.sender;

        uint256 approvedAmount = token.allowance(caller, address(this));
        require(approvedAmount >= _amount, "ERR:AA");//AA => Approved Amount

        require(_minterIndex < 3, "ERR:WM"); //WM => Wrong Minter

        bool raptorCheck;

        for(uint8 i = 0; i < 8; ){

            if(
                details.sortedRaptors[i].tokenId == _raptor
                && details.sortedRaptors[i].minterIndex == _minterIndex
            ){
                raptorCheck = true;
            }


            unchecked{
                i++;
            }
        }

        require(raptorCheck, "ERR:WD");//WD => Wrong Details

        require(uint(_bet) <= 3, "ERR:BT");//BT => Bet Type

        token.BurnFrom(caller, _amount);

        details.betterDetails[caller] = BetterDetails({
            tokenId: _raptor,
            minterIndex: _minterIndex,
            valueBet: _amount,
            betType: _bet
        });
    }

}