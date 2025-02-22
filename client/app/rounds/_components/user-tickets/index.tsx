'use client';

import { useAccount } from 'wagmi';
import Details from './details';

export default function UserTickets() {
	const { address } = useAccount();

	if (!address) return null;

	return <Details player={address} />;
}
