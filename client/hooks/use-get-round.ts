import { letoConfig } from '@/configs/leto-contract-config';
import { constructRound } from '@/utils/construct-round';
import { useReadContract } from 'wagmi';

export const useGetRound = (roundId?: number) => {
	const { data, ...result } = useReadContract({
		...letoConfig,
		functionName: 'getRoundData',
		args: roundId ? [BigInt(roundId)] : undefined,
	});

	const round = data && constructRound(data);

	return { round, ...result };
};
