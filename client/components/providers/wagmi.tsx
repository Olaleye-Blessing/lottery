'use client';

import { PropsWithChildren } from 'react';
import { walletConfig } from '@/configs/wallet';
import { WagmiProvider as Provider } from 'wagmi';

export default function WagmiProvider({ children }: PropsWithChildren) {
	return <Provider config={walletConfig}>{children}</Provider>;
}
