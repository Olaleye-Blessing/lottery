import {
	ContractFunctionExecutionError,
	ContractFunctionRevertedError,
} from 'viem';

export const getGeneralContractError = (error: unknown) => {
	if (
		!(error instanceof ContractFunctionExecutionError) &&
		!(error instanceof ContractFunctionRevertedError)
	) {
		return error instanceof Error
			? error.message
			: 'An unknown error occurred';
	}

	const originalError = error.cause;

	if (!(originalError instanceof ContractFunctionRevertedError)) {
		return error instanceof Error
			? error.message
			: 'An unknown error occurred';
	}

	return originalError;
};
