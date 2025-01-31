'use client';

import Loading from '@/app/loading';
import EtherLabel from '@/components/ether-label';
import { useGetRound } from '@/hooks/use-get-round';

export default function CurrentPool() {
	const { round, error: roundError } = useGetRound();

	console.log(round);

	return (
		<section className='mt-16 bg-gray-800 rounded-2xl p-8 text-center max-w-2xl mx-auto'>
			<h2 className='text-2xl font-semibold mb-2'>Current Prize Pool</h2>
			<>
				{round ? (
					<>
						<div className='text-5xl md:text-6xl font-bold bg-gradient-to-r from-purple-500 to-blue-500 bg-clip-text text-transparent mb-4'>
							<EtherLabel
								label={round.prize}
								iconClassName=' text-[1.5rem]'
							/>
						</div>
						<p className='text-gray-400'>
							Total tickets sold: {round.totalTickets}
						</p>
					</>
				) : roundError ? (
					<p className='error text-center'>There is an error</p>
				) : (
					<Loading />
				)}
			</>
		</section>
	);
}
