pragma solidity 0.8.15;
//Defining the stats that every raptor will have
struct RaptorStats {
    uint64 speed;
    uint64 strength;
    uint64 fightsWon;
    uint64 fightsLost;
    uint64 quickPlayRacesWon;
    uint64 compRacesWon;
    uint64 deathRacesWon;
    uint64 deathRacesSurvived;
    uint64 totalRacesTop3Finish;
    uint64 cooldownTime;
}
