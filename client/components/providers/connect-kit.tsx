'use client';

import { PropsWithChildren } from 'react';
import { ConnectKitProvider as Provider } from 'connectkit';

export default function ConnectKitProvider({ children }: PropsWithChildren) {
	return <Provider>{children}</Provider>;
}
