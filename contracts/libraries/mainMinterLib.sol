//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library minterLib {
    //Emits an event declaring that the price has increased
    //It is declared in here & in the minter contract to show up correctly on the blockchain explorer
    event PriceIncrease(uint256 newPrice);

    //Checks if the amount crosses a multiple of 1000 & returns a bool
    function crossesThreshold(uint256 _amount, uint256 _totalSupply)
        internal
        pure
        returns (bool)
    {
        //If the total supply + the amount is smaller than 1000 return false
        if (_totalSupply + _amount < 1000) return false;

        //Calculate the remainder of (totalsupply + amount) / 1000
        uint256 remainder = (_totalSupply + _amount) % 1000;

        //If the remainder is between 0 & 9 & that the remainder is less than amount return true else return false
        if (remainder >= 0 && remainder < 10 && remainder < _amount) {
            return true;
        } else {
            return false;
        }
    }

    //get amounts on each side of the 1k split
    //for example: amount 5, totalSupply 998
    //amountBefore 2, amountAfter 3
    function getAmounts(uint256 _amount, uint256 _totalSupply)
        internal
        pure
        returns (uint8 amountBefore, uint8 amountAfter)
    {
        //increment through the amount
        for (uint8 i = 1; i <= _amount; ) {
            //If this croses the 10-00 mint threshold
            if (crossesThreshold(i, _totalSupply)) {
                //Split the amount before
                amountBefore = uint8(i);
                amountAfter = uint8(_amount - amountBefore);
                break;
            }

            //Removing safemath wrapper to save gas as we know this uint88 will not reach 255 & therefor there is no possible overflow
            unchecked {
                i++;
            }
        }
    }

    //Gets the price for a given amount, price & current Minted amount
    //Checks to see if the amount + current minted amount crosses the a multiple of 1000
    //If so it gets the amounts on each side & calculates the price accordingly
    function getPrice(
        uint8 _amount,
        uint256 price,
        uint16 totalMintSupply
    ) internal pure returns (uint256 givenPrice) {
        //Check that the amount passed in is less than or equal to 10
        require(_amount <= 10, "Err:RA"); //RA => Requested Amount

        //Check if the requested amount crosses the 1000 mint threshold
        bool answer = crossesThreshold(_amount, totalMintSupply);

        //If answer does equal true
        if (answer) {
            //Get the split amounts
            (uint8 amountBefore, uint8 amountAfter) = getAmounts(
                _amount,
                totalMintSupply
            );

            //Calculate the fullprice
            givenPrice = (price * amountBefore) + (price * 2 * amountAfter);
        } else {
            //Calculate the full price
            givenPrice = price * _amount;
        }
    }

    //Calculates the sum of the shares array
    function totalShares(uint16[] memory shares)
        internal
        pure
        returns (uint16 result)
    {
        //Iterate through the array
        for (uint8 i = 0; i < shares.length; ) {
            //Add each element in the array to the result
            result += shares[i];

            //Remove the safe math wrapper to save gas as i will not be larger than 255
            unchecked {
                i++;
            }
        }
    }
}
