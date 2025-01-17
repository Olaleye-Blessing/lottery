'use client';

import { http, createConfig } from 'wagmi';
import { baseSepolia } from 'wagmi/chains';
import { coinbaseWallet, injected, metaMask } from 'wagmi/connectors';
import { clientEnv } from '@/constants/env/client';
import { getDefaultConfig } from 'connectkit';
import { appDescription } from '@/utils/site-metadata';
import { anvil } from './chains';

export const walletConfig = createConfig(
	getDefaultConfig({
		ssr: true,
		connectors: [
			injected(),
			metaMask({
				dappMetadata: {
					// TODO: Update metata
					name: 'Lottery',
					url: '',
					iconUrl: '',
				},
			}),
			coinbaseWallet(),
		],
		chains: (() =>
			process.env.NODE_ENV === 'production' ? [baseSepolia] : [anvil])(),
		transports:
			process.env.NODE_ENV === 'production'
				? {
						[baseSepolia.id]: http(
							clientEnv.NEXT_PUBLIC_BASE_SEPOLIA_ALCHEMY_RPC_URL
						),
				  }
				: {
						[anvil.id]: http(),
				  },

		// Required API Keys
		walletConnectProjectId: clientEnv.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID,

		// TODO: Update this info
		// Required App Info
		appName: 'Crowdchain',

		// Optional App Info
		appDescription: appDescription,
		appUrl: '', // your app's url
		appIcon: '', // your app's icon, no bigger than 1024x1024px (max. 1MB)
	})
);
