//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IGame {

    //This function changes the distance stored in the game library
    function setDist(uint32 dist) external ;

    //Select Race only callable by admin
    function raceSelect(uint8 choice) external;

    //returns the array of tokenIDs currently in the queue - this also returns 0 in unfilled slots
    function getCurrentQueue() external view returns (uint16[8] memory raptors);

    //Quickplay Entry
    function enterRaptorIntoQuickPlay(uint8 minterIndex, uint16 raptor)
        external
        payable;

    //Competitive Entry
    function enterRaptorIntoComp(uint8 minterIndex, uint16 raptor)
        external
        payable;

    //DeathRace Entry
    function enterRaptorIntoDR(uint8 minterIndex, uint16 raptor)
        external
        payable;

}
