pragma solidity 0.8.15;

interface IBet {
    function openBetting(uint16[] memory _raptors, uint8[] memory _minterIndexes) external;

    function closeBetting(Results memory _results) external;
}