import { HardhatUserConfig } from 'hardhat/config';

import '@nomicfoundation/hardhat-toolbox';
import '@nomicfoundation/hardhat-ethers';
import 'hardhat-contract-sizer';
import 'hardhat-deploy';

import { ENV, getForkNetworkConfig, getHardhatNetworkConfig, getNetworkConfig } from './config';

const config: HardhatUserConfig = {
  solidity: '0.8.24',
  namedAccounts: {
    deployer: 0,
    user1: 1,
    user2: 2,
  },
  defaultNetwork: 'hardhat',
  networks: {
    mainnet: getNetworkConfig('mainnet'),
    sepolia: getNetworkConfig('sepolia'),
    hardhat: ENV.FORKING_NETWORK ? getForkNetworkConfig(ENV.FORKING_NETWORK) : getHardhatNetworkConfig(),
    localhost: ENV.FORKING_NETWORK ? getForkNetworkConfig(ENV.FORKING_NETWORK) : getHardhatNetworkConfig(),
  },
  gasReporter: { enabled: ENV.REPORT_GAS },
  contractSizer: { runOnCompile: ENV.OPTIMIZER },
  etherscan: { apiKey: ENV.ETHERSCAN_API_KEY },
  paths: {
    deploy: 'deploy/',
    deployments: 'deployments/',
    sources: 'contracts/',
  },
  external: ENV.FORKING_NETWORK
    ? {
        deployments: {
          hardhat: ['deployments/' + ENV.FORKING_NETWORK],
          local: ['deployments/' + ENV.FORKING_NETWORK],
        },
      }
    : undefined,
};

export default config;
