import { LETO_ADDRESS } from '@/constants/contracts';
import { letoAbi } from '@/lib/contracts/leto/abi';

export const letoConfig = {
	abi: letoAbi,
	address: LETO_ADDRESS,
} as const;
