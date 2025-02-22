import { waitForTransactionReceipt } from '@wagmi/core';
import { Address } from 'viem';
import { useConfig } from 'wagmi';

export const useConfirmTx = () => {
	const config = useConfig();

	const confrimHash = async ({
		txHash,
		confirmations = 1,
	}: {
		txHash: Address;
		confirmations?: number;
	}) => {
		await waitForTransactionReceipt(config, {
			hash: txHash,
			confirmations,
		});
	};

	return { confrimHash };
};
