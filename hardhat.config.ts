import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-deploy";
import * as dotenv from "dotenv";

dotenv.config();

const DEFAULT_COMPILER_SETTINGS =
{
  version: "0.8.28",
  settings: {
    optimizer: {
      enabled: true,
      runs: 1,
    },
  },
}

const UNISWAP_INTEGRATION_COMPILER_SETTINGS = {
  version: "0.8.26",
  settings: {
    viaIR: true,
    optimizer: {
      enabled: true,
      runs: 1,
    },
  },
}

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      DEFAULT_COMPILER_SETTINGS,
      UNISWAP_INTEGRATION_COMPILER_SETTINGS,
    ],
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      chainId: 1480,
      // forking: {
      //   url: process.env.VANA_RPC_URL || "",
      //   blockNumber: 2_500_000,
        // url: process.env.MOKSHA_RPC_URL || "",
        // blockNumber: 2_569_780,
      // },
      chains: {
        1480: {
          hardforkHistory: {
            london: 0,
          }
        },
        14800: {
          hardforkHistory: {
            london: 0,
          }
        },
      },
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
      url: process.env.MOKSHA_RPC_URL || "",
      chainId: 14800,
      accounts:
        process.env.DEPLOYER_PRIVATE_KEY !== undefined
          ? [process.env.DEPLOYER_PRIVATE_KEY]
          : [],
      allowUnlimitedContractSize: true,
    },
  },
  etherscan: {
    apiKey: {
      // Is not required by blockscout. Can be any non-empty string
      vana: "empty",
      moksha: "empty",
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
          apiURL: process.env.MOKSHA_API_URL || "",
          browserURL: process.env.MOKSHA_BROWSER_URL || "",
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
