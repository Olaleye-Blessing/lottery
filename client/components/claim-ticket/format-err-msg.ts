import { formatContractErr } from '@/utils/format-contract-error';

type CustomDonateErrorType =
	| 'Lottery__IncorrectRoundStatus'
	| 'Lottery__TicketNotRegistered'
	| 'Lottery__TicketHasBeenClaimed'
	| 'Lottery__TicketNotOwner'
	| 'Lottery__FundTransferFailed()';

export const formatErrMsg = (error: unknown) => {
	const originalError = formatContractErr(error);

	if (typeof originalError === 'string') return originalError;

	const errorName = originalError.data?.errorName as CustomDonateErrorType;

	if (errorName === 'Lottery__IncorrectRoundStatus') {
		return 'Status error';
	}

	if (errorName === 'Lottery__TicketHasBeenClaimed') {
		return `Ticket has been claimed`;
	}

	if (errorName === 'Lottery__TicketNotOwner') {
		return 'Ticket does not belong to this player';
	}

	return 'An unknown contract error occurred. Try again later!';
};
