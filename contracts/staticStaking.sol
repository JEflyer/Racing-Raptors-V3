//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//Import the interface for the stats contract
import "./interfaces/IStats.sol";

//Imported the context library for safe usage of msg.sender
import "@openzeppelin/contracts/utils/Context.sol";

//Import the interface for ERC20
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//Import the interface for ERC721A
import "./ERC721A/IERC721A.sol";

contract StaticStaking{

    address private admin;

    IERC20 private token;


    IERC721A private minter1;
    IERC721A private minter2;

    IStats private stats;

    uint256 private stakingRewardPerBlock;

    constructor(address _minter1, address _minter2, address _token, address _stats, uint256 _stakingRewardPerBlock){
        token = IERC20(_token);

        minter1 = IERC721A(_minter1);
        minter2 = IERC721A(_minter2);

        stats = IStats(_stats);

        admin = _msgSender();

        stakingRewardPerBlock = _stakingRewardPerBlock;
    }

    function stake(uint16 tokenId, uint8 minterIndex) external {
        
    }


}