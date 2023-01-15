require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
    /** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: "0.8.15",
    gasReporter: {
        currency: 'USD',
        gasPrice: 31,
        enabled: true
    },
    mocha: {
        timeout: 1000000
    },
    contractSizer: {
        alphaSort: true,
        disambiguatePaths: false,
        runOnCompile: true,
        strict: true
    }
};