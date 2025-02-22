'use client';
import { useAccount } from 'wagmi';
import Tickets from './tickets';
import ConnectWalletButton from '@/components/navbar/wallet/connect';

export default function Dashboard() {
	const account = useAccount();

	if (!account.address)
		return (
			<main className='laytout flex-1 mt-16 flex items-center justify-center'>
				<ConnectWalletButton label='Connect Wallet' />
			</main>
		);

	return (
		<main className='layout flex-1'>
			<Tickets player={account.address} />
		</main>
	);
}
