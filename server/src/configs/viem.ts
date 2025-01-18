import { createPublicClient, defineChain, fallback, http } from 'viem';
import { baseSepolia } from 'viem/chains';
import { envVars } from '../utils/env-data';

const anvil = defineChain({
  id: 7001,
  name: 'Anvil',
  nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
  rpcUrls: {
    default: { http: [envVars.ANVIL_RPC] },
  },
  testnet: true,
});

// TODO: Include other possible RPC URLs
export const publicClient = createPublicClient({
  chain: envVars.NODE_ENV === 'production' ? baseSepolia : anvil,
  transport: fallback(
    envVars.NODE_ENV === 'production'
      ? [http(envVars.BASE_SEPOLIA_ALCHEMY_RPC_URL), http()]
      : [http()],
  ),
  batch: {
    multicall: true,
  },
});
