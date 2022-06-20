pragma solidity 0.8.15;

//import ERC20
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//import ERC20burnable
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract RaptorCoin is ERC20, ERC20Burnable {
    address private admin;

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

    function mint(uint256 amount, address to) external onlyApproved
}
