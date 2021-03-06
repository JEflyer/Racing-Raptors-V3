//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

struct GameVars {
    uint16[8] raptors;
    uint16[8] randomness;
    uint8[8] minterIndexes;
    uint8[2] fighters;
    uint8 fightWinner;
    uint8[3] places;
    bool dr;
}
