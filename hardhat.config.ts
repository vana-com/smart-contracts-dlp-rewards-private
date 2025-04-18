import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-deploy";
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1,
      },
    },
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      // forking: {
      //   url: "https://archive.vana.org",
      //   // url: "https://rpc.moksha.vana.org",
      //   // blockNumber: 1288639,
      // },
    },
    vana: {
      url: process.env.VANA_RPC_URL || "",
      accounts:
        process.env.DEPLOYER_PRIVATE_KEY !== undefined
          ? [process.env.DEPLOYER_PRIVATE_KEY]
          : [],
      allowUnlimitedContractSize: true,
    },
    moksha: {
      allowUnlimitedContractSize: true,
      url: process.env.MOKSHA_RPC_URL || "",
      chainId: 14800,
      accounts:
        process.env.DEPLOYER_PRIVATE_KEY !== undefined
          ? [process.env.DEPLOYER_PRIVATE_KEY]
          : [],
    }
  },
  etherscan: {
    apiKey: {
      // Is not required by blockscout. Can be any non-empty string
      vana: "abc",
      moksha: "abc",
    },
    customChains: [
      {
        network: "vana",
        chainId: 1480,
        urls: {
          apiURL: process.env.VANA_API_URL || "",
          browserURL: process.env.VANA_BROWSER_URL || "",
        },
      },
      {
        network: "moksha",
        chainId: 14800,
        urls: {
          apiURL: "https://api.moksha.vanascan.io/api/",
          browserURL: "https://moksha.vanascan.io",
        },
      },
      {
        network: "maya",
        chainId: 14808,
        urls: {
          apiURL: process.env.MAYA_API_URL || "",
          browserURL: process.env.MAYA_BROWSER_URL || "",
        },
      },
    ],
  },
  sourcify: {
    enabled: false,
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 1800000,
  },
  gasReporter: {
    enabled: true,
    excludeContracts: ["mocks", "tests"],
  },
};
export default config;
