import { getGeneralContractError } from '@/utils/contract-error';

type CustomCreateErrorType =
	| 'Lottery__RoundNotActive'
	| 'Lottery__InvalidTicketPaymentAmount'
	| 'Lottery__InvalidTicketNumbers';

export const getCreateErrMsg = (error: unknown) => {
	const originalError = getGeneralContractError(error);

	if (typeof originalError === 'string') return originalError;

	const errorName = originalError.data?.errorName as CustomCreateErrorType;
	const defaultErrMsg =
		'Unable to buy ticket(s). Try agan later or contact support';

	if (errorName === 'Lottery__RoundNotActive') {
		return 'Round is not active.';
	}

	if (errorName === 'Lottery__InvalidTicketPaymentAmount') {
		return 'Incorrect ticket amount';
	}

	if (errorName === 'Lottery__InvalidTicketNumbers') {
		return (originalError.data?.args?.[0] as string) || defaultErrMsg;
	}

	return defaultErrMsg;
};
