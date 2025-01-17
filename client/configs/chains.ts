import { defineChain } from 'viem';
import { clientEnv } from '@/constants/env/client';

export const anvil = defineChain({
	id: clientEnv.NEXT_PUBLIC_ANVIL_CHAIN_ID,
	name: 'Anvil',
	nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
	rpcUrls: { default: { http: [clientEnv.NEXT_PUBLIC_ANVIL_RPC_URL] } },
	testnet: true,
});
