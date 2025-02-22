import { letoConfig } from '@/configs/leto-contract-config';
import { constructRound } from '@/utils/construct-round';
import { useReadContract } from 'wagmi';

type IUseGetRound = {
	roundId?: number;
	enabled?: boolean;
};

export const useGetRound = (info?: IUseGetRound) => {
	const { roundId, enabled } = info || {};

	const { data, ...result } = useReadContract({
		...letoConfig,
		functionName: 'getRoundData',
		args: roundId != undefined ? [BigInt(roundId)] : undefined,
		query: { enabled },
	});

	const round = data && constructRound(data);

	return { round, ...result };
};
