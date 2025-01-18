'use client';

import { Button } from '@/components/ui/button';
import { ConnectKitButton } from 'connectkit';

export default function ConnectWalletButton() {
	return (
		<ConnectKitButton.Custom>
			{({ isConnected, isConnecting, show, truncatedAddress }) => {
				return (
					<Button className='connection__btn' onClick={show}>
						{isConnecting
							? 'Connecting...'
							: isConnected
							? truncatedAddress
							: 'Connect'}
					</Button>
				);
			}}
		</ConnectKitButton.Custom>
	);
}
