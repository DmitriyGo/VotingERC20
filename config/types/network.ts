export type DevNetwork = 'localhost' | 'hardhat';
export type ProdNetwork = 'mainnet' | 'sepolia';

export type Network = DevNetwork | ProdNetwork;

export const FORKING_NETWORKS = ['mainnet'] as const;
export type ForkingNetwork = (typeof FORKING_NETWORKS)[number];

export type RpcUrl =
  | `https://eth-${Network}.g.alchemy.com/v2/${string}`
  | `https://${Network}.infura.io/v3/${string}`
  | `http://localhost:${number}`;

export type ConfigPerNetwork<T> = Record<Network, T>;
