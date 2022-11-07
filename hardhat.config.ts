import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";

import "hardhat-deploy";

dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const GAS_PRICE = parseFloat(process.env.GAS_PRICE || "1");

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY ?? "";

const config: HardhatUserConfig = {
  defaultNetwork: "localhost",
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000,
            details: {
              peephole: true,
              inliner: true,
              jumpdestRemover: true,
              orderLiterals: true,
              deduplicate: true,
              cse: true,
              constantOptimizer: true,
              yul: true,
              yulDetails: {
                stackAllocation: true,
              },
            },
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      chainId: 137,
      forking: {
        blockNumber: 34637771,
        url: "https://polygon-rpc.com",
      },
    },
    localhost: {
      chainId: 137,
      url: "http://localhost:8545",
    },
    matic: {
      timeout: 1000000,
      chainId: 137,
      url: "http://localhost:1248",
      gasPrice: GAS_PRICE * 10 ** 9,
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  namedAccounts: {
    deployer: {
      default: 0, // this will by default take the first account as deployer
    },
  },
};

export default config;
