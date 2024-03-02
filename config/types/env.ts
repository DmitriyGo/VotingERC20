import { z } from 'zod';

import { FORKING_NETWORKS, ForkingNetwork } from './network';

export interface Environment {
  readonly INFURA_KEY: string;
  readonly ETHERSCAN_API_KEY?: string;
  readonly OPTIMIZER: boolean;
  readonly COVERAGE: boolean;
  readonly REPORT_GAS: boolean;
  readonly MNEMONIC_DEV?: string;
  readonly MNEMONIC_PROD?: string;
  readonly FORKING_NETWORK?: ForkingNetwork;
}

export const envSchema = z.object({
  INFURA_KEY: z.string(),
  ETHERSCAN_API_KEY: z.string().optional(),
  OPTIMIZER: z.literal(true).or(z.literal(false)).default(false),
  COVERAGE: z.literal(true).or(z.literal(false)).default(false),
  REPORT_GAS: z.literal(true).or(z.literal(false)).default(false),
  MNEMONIC_DEV: z.string().optional(),
  MNEMONIC_PROD: z.string().optional(),
  FORKING_NETWORK: z.enum([...FORKING_NETWORKS]).optional(),
});

type SchemaType = z.infer<typeof envSchema>;

const _: Environment = {} as SchemaType;
const __: SchemaType = {} as Environment;
