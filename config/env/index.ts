import 'dotenv/config';

import { Environment, envSchema } from '../types/env';

const result = envSchema.safeParse(process.env);

if (!result.success) {
  console.error(result.error);
  process.exit(1);
}

export const ENV: Environment = result.data;
