import { PropsWithChildren } from 'react';
import WagmiProvider from './wagmi';
import ReactQueryProvider from './react-query';
import ConnectKitProvider from './connect-kit';

export default function Providers({ children }: PropsWithChildren) {
	return (
		<WagmiProvider>
			<ReactQueryProvider>
				<ConnectKitProvider>{children}</ConnectKitProvider>
			</ReactQueryProvider>
		</WagmiProvider>
	);
}
