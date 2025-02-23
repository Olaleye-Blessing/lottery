'use client';

import Loading from '@/app/loading';
import { letoConfig } from '@/configs/leto-contract-config';
import { useGetRound } from '@/hooks/use-get-round';
import { Address } from 'viem';
import { useReadContract } from 'wagmi';
import PlayerTickets from '@/components/tickets';

export default function Details({ player }: { player: Address }) {
	const { round } = useGetRound();
	const { data, error } = useReadContract({
		...letoConfig,
		functionName: 'getPlayerTickets',
		account: player,
	});

	const [ids = [], tickets = []] = data || [];

	return (
		<section className='bg-gray-800/50 rounded-lg mt-8 p-6 backdrop-blur-sm'>
			<header>
				<h2>Your Tickets</h2>
			</header>
			<div>
				{data && round ? (
					<>
						{tickets.length === 0 ? (
							<p>You have no tickets</p>
						) : (
							<PlayerTickets
								tickets={tickets}
								ids={ids}
								round={round}
							/>
						)}
					</>
				) : error ? (
					<p>
						There is an error getting your tickets. Please try again
						later
					</p>
				) : (
					<Loading />
				)}
			</div>
		</section>
	);
}
