import { Address } from 'viem';
import { clientEnv } from './env/client';

export const LETO_ADDRESS = clientEnv.NEXT_PUBLIC_LETO_ADDRESS as Address;
