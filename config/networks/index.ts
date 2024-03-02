import { HardhatNetworkUserConfig, NetworkUserConfig } from 'hardhat/types';

import { GWEI } from '../constants';
import { ENV } from '../env';
import { Network } from '../types';

const { INFURA_KEY, MNEMONIC_DEV, MNEMONIC_PROD } = ENV;

interface NetworkConfig {
  rpcUrl: string;
  chainId: number;
  mnemonic?: string;
  gas?: number;
  gasPrice?: number;
  blockGasLimit?: number;
  timeout?: number;
  initialBaseFeePerGas?: number;
}

const networks: Record<Network, NetworkConfig> = {
  mainnet: {
    rpcUrl: `https://mainnet.infura.io/v3/${INFURA_KEY}`,
    chainId: 1,
    mnemonic: MNEMONIC_PROD,
    blockGasLimit: 300 * 10 ** 6,
  },
  sepolia: {
    rpcUrl: `https://sepolia.infura.io/v3/${INFURA_KEY}`,
    chainId: 11155111,
    mnemonic: MNEMONIC_DEV,
    gas: 1_250_000,
    timeout: 999999,
  },
  hardhat: {
    rpcUrl: 'http://localhost:8545',
    chainId: 31337,
    mnemonic: MNEMONIC_DEV,
    blockGasLimit: 300 * 10 ** 6,
    initialBaseFeePerGas: 0,
  },
  localhost: {
    rpcUrl: 'http://localhost:8545',
    chainId: 31337,
    mnemonic: MNEMONIC_DEV,
    gas: 1_250_000,
    timeout: 999999,
    gasPrice: 70 * GWEI,
  },
};

const getBaseNetworkConfig = (network: Network): NetworkUserConfig => ({
  accounts: networks[network].mnemonic ? { mnemonic: networks[network].mnemonic } : undefined,
  chainId: networks[network].chainId,
  gas: networks[network].gas,
  gasPrice: networks[network].gasPrice,
  blockGasLimit: networks[network].blockGasLimit,
  timeout: networks[network].timeout,
  initialBaseFeePerGas: networks[network].initialBaseFeePerGas,
});

export const getNetworkConfig = (network: Network): NetworkUserConfig => ({
  ...getBaseNetworkConfig(network),
  url: networks[network].rpcUrl,
});

export const getForkNetworkConfig = (network: Network): HardhatNetworkUserConfig => {
  const baseConfig = getBaseNetworkConfig(network) as HardhatNetworkUserConfig;
  return {
    ...baseConfig,
    chainId: networks.hardhat.chainId,
    forking: {
      url: networks[network].rpcUrl,
      blockNumber: 19212830,
    },
    accounts: { mnemonic: networks[network].mnemonic },
  };
};

export const getHardhatNetworkConfig = (): HardhatNetworkUserConfig => {
  return getBaseNetworkConfig('hardhat') as HardhatNetworkUserConfig;
};
