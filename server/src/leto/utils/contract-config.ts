import { LETO_ADRESS } from '../../constants/contracts';
import { letoAbi } from './abi';

export const letoConfig = {
  abi: letoAbi,
  address: LETO_ADRESS,
} as const;
