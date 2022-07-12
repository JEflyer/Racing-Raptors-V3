//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Claws is IERC20, ERC20Burnable{

    IERC20 private token;


    constructor(address _token){
        token = IERC20(_token);

    }


    function tradeToClaws(uint256 amount) external {
        
        address caller = _msgSender();
        
        uint256 allowedAmount = token.allowance(caller, address(this), amount);

        require(allowedAmount >= amount, "ERR:AA");//AA => Approved Amount

        token.burnFrom(caller,amount);

        _mint(caller, amount * 80 / 100);
    }

    function exchangeClaws(uint256 amount) external {
        address caller = _msgSender();

        uint256 balance = balanceOf(caller);

        require(balance >= amount, "ERR:NE");//NE => Not Enough

        _burn(caller, amount);

        token.mint(caller, amount * 4 /3);
    }

}