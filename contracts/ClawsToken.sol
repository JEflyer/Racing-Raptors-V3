//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ICoin.sol";

contract Claws is IERC20, ERC20Burnable{

    ICoin private token;


    constructor(address _token)ERC20("Claws","CLW"){
        token = ICoin(_token);

    }


    function tradeToClaws(uint256 amount) external {
        
        address caller = _msgSender();
        
        uint256 allowedAmount = token.allowance(caller, address(this));

        require(allowedAmount >= amount, "ERR:AA");//AA => Approved Amount

        token.BurnFrom(caller,amount);

        _mint(caller, amount * 80 / 100);
    }

    function exchangeClaws(uint256 amount) external {
        address caller = _msgSender();

        uint256 balance = balanceOf(caller);

        require(balance >= amount, "ERR:NE");//NE => Not Enough

        _burn(caller, amount);

        token.mint(amount * 45 /40, caller);
    }

}