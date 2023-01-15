//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IStats {

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


    function instantiateStats(uint256 tokenId) external returns (bool);

    //For a minterIndex & tokenId return the Raptor Stats struct
    function getStats(uint256 index, uint256 tokenId)
        external
        view
        returns (RaptorStats memory);

    //For a minterIndex & tokenId return the raptors speed
    function getSpeed(uint256 index, uint256 tokenId)
        external
        view
        returns (uint64);

    //For a minterIndex & tokenId return the raptors strength
    function getStrength(uint256 index, uint256 tokenId)
        external
        view
        returns (uint64);

    function increaseTop3Finishes(uint256 index, uint256 tokenId) external returns(bool);


    //For a minterIndex & tokenId return the raptors cooldown time
    //A raptor will only be on cooldown if the raptor is injured
    function getCooldownTime(uint256 index, uint256 tokenId)
        external
        view
        returns (uint64);

    //For a minterIndex & tokenId increase the raptors speed by increaseAmount
    function increaseSpeed(
        uint256 index,
        uint256 tokenId,
        uint64 increaseAmount
    ) external returns (bool);

    //For a minterIndex & tokenId increase the raptors strength by increaseAmount
    function increaseStrength(
        uint256 index,
        uint256 tokenId,
        uint64 increaseAmount
    ) external returns (bool);

    //For a minterIndex & tokenId increase the raptors fightsWon stat by 1
    function increaseFightsWon(uint256 index, uint256 tokenId)
        external
        returns (bool);

    //For a minterIndex & tokenId increase the raptors fightsLost stat by 1
    function increaseFightsLost(uint256 index, uint256 tokenId)
        external
        returns (bool);

    //For a minterIndex & tokenId increase the raptors QPRacesWon stat by 1
    function increaseQPRacesWon(uint256 index, uint256 tokenId)
        external
        returns (bool);

    //For a minterIndex & tokenId increase the raptors CompRacesWon stat by 1
    function increaseCompRacesWon(uint256 index, uint256 tokenId)
        external
        returns (bool);

    //For a minterIndex & tokenId increase the raptors DeathRacesWon stat by 1
    function increaseDRWon(uint256 index, uint256 tokenId) external returns (bool);

    //For a minterIndex & tokenId increase the raptors DeathRacesSurvived stat by 1
    function increaseDRSurvived(uint256 index, uint256 tokenId)
        external
        returns (bool);

    //For a minterIndex & tokenId increase the raptors cooldownTime to a period of time from now
    function increaseCooldownTime(uint256 index, uint256 tokenId)
        external
        returns (bool);

    function owns(
        address _query,
        uint256 index,
        uint256 tokenId
    ) external view returns (bool);

    function ownerOf(uint256 index, uint256 tokenId)
        external
        view
        returns (address);

    function checkApproval(uint256 index, uint256 tokenId)
        external
        view
        returns (bool);

    function burn(uint8 minterIndex, uint256 tokenId) external returns(bool);

    function checkMinterIndex(uint8 minterIndex) external view returns(address);

}
