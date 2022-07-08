pragma solidity 0.8.15;

interface ICoin {
    
    function mint(uint256 amount, address to) external;

    function burn(uint256 amount) external virtual;

    function burnFrom(address account, uint256 amount) external virtual;

    function transfer(address to, uint256 amount)
        external
        virtual
        override
        returns (bool);

    
}