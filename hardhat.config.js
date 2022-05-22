/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("@nomiclabs/hardhat-waffle");
require("dotenv").config();

module.exports = {
  solidity: "0.8.0",
  networks: {
    rinkeby: {
      url: process.env.TEST_ALCHEMY_API_KEY,
      accounts: [process.env.PRIVATE_KEY]
    },
  },                    
};
