pragma solidity 0.8.15;

//import ERC20
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//import ERC20burnable
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

//import UniswapV2Router02 interface
import {IUniswapV2Router02} from "./FlatRouter.sol";

contract RaptorCoin is ERC20, ERC20Burnable {
    address private admin;

    address private WMatic;

    address private uniswapV2RouterAddr;

    address private liquidityLockedAddress;

    uint8 private liquidityPercent;

    mapping(address => bool) private approved;

    constructor(
        address _WMatic,
        address _uniswapV2RouterAddr,
        address _liquidityLockedAddress
    ) ERC20("RaptorCoin", "RC") {
        admin = msg.sender;
        liquidityPercent = 15;
        WMatic = _WMatic;
        uniswapV2RouterAddr = _uniswapV2RouterAddr;
        liquidityLockedAddress = _liquidityLockedAddress;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "ERR:NA"); //NA => Not Admin
        _;
    }

    modifier onlyApproved() {
        require(approved[msg.sender], "ERR:NG"); //NG => Not Game
        _;
    }

    function addApprovedAddress(address _addr) external onlyAdmin {
        approved[_addr] = true;
    }

    function removeApprovedAddress(address _addr) external onlyAdmin {
        delete approved[_addr];
    }

    function mint(uint256 amount, address to) external onlyApproved {
        require(to != address(0), "ERR:ZA");
        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function Burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function BurnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    //Send 2% to the liquidty pool
    //Burn 1%
    //This function is a part of the ERC20 standard implementation
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        //Call for _msgSender() once to avoid multiple function calls
        address owner = _msgSender();

        //Calculate the liqidity fee
        uint256 liquidityFee = (amount * liquidityPercent) / 1000;

        //calculate the burn fee
        uint256 burnFee = amount / 100;

        //Transfer the amount minus the liquidity fee from the owner address to the to address
        _transfer(owner, to, amount - liquidityFee - burnFee);

        //Transfer the liquidity fee & burn fee from the owner address to this contracts address
        _transfer(owner, address(this), liquidityFee + burnFee);

        //Add the  liquidity fee to the liquidity pool
        addLiquidity(liquidityFee);

        //Burn the burn fee
        _burn(address(this), burnFee);

        //Return a true vulue to signify a complete trade
        return true;
    }

    //This function must only be callable by the transfer function
    function addLiquidity(uint256 tokenAmount) internal {
        //We define a uint variable to be used later
        uint256 maticAmount;
        uint256 tokenAmountToAdd;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WMatic;

        //Convert 50% of the liquidity fee to matic & then deposit both into the liquidity pool
        tokenAmountToAdd = tokenAmount / 2;

        uint256 initialBal = address(this).balance;

        uint256 tokenAmountToSwap = tokenAmount - tokenAmountToAdd;

        // Give permission for the router contract to use this contracts token balance for a total of the given token amount
        _approve(address(this), uniswapV2RouterAddr, tokenAmountToSwap);

        IUniswapV2Router02(uniswapV2RouterAddr)
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmountToSwap,
                0,
                path,
                address(this),
                block.timestamp
            );

        maticAmount = address(this).balance - initialBal;

        //Check that the balance is enough to cover the cost of adding to liquidty
        require(address(this).balance >= maticAmount, "ERR:NF"); //NF => No Funds

        // Checking that maticAmount is not equal to zero
        require(maticAmount != 0, "ERR:CA"); //CA => Calculating Amount

        // Give permission for the router contract to use this contracts token balance for a total of the given token amount
        _approve(address(this), uniswapV2RouterAddr, tokenAmountToAdd);

        // add the liquidity
        IUniswapV2Router02(uniswapV2RouterAddr).addLiquidityETH{
            value: maticAmount
        }(
            address(this), //TokenA
            tokenAmountToAdd,
            0, //minAmount0Out
            0, //minAmount1Out
            liquidityLockedAddress, //Owner of the liquidity
            block.timestamp //When it should be processed by, for this we set the time as right now, this only needs to have extra time if calling this function on it's own transaction
        );
    }
}
