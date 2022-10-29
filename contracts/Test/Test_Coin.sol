pragma solidity 0.8.15;

//import ERC20
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//import ERC20burnable
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


contract TestToken is ERC20, ERC20Burnable {
    address private admin;

    address private WMatic;

    address private uniswapV2RouterAddr;

    address private liquidityLockedAddress;

    uint8 private liquidityPercent;

    mapping(address => bool) private approved;

    constructor() ERC20("RaptorCoin", "RC") {
        admin = msg.sender;
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

}
