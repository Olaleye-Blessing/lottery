'use client';

import { Clock, Sparkles } from 'lucide-react';
import Loading from '@/app/loading';
import EtherLabel from '@/components/ether-label';
import { useGetRound } from '@/hooks/use-get-round';
import { useGetTicketPrice } from '@/hooks/use-get-ticket-price';
import SmallCountdownTimer from '@/components/countdown-timer/small-timer';

export default function Header() {
	const { ticketPrice, ticketPriceError } = useGetTicketPrice();
	const { round, error } = useGetRound();

	return (
		<header className='bg-gray-800 rounded-lg p-6 my-8'>
			{round ? (
				<>
					<div className='flex items-center gap-2 justify-between flex-wrap mb-2'>
						<div className='flex items-center gap-2 justify-between'>
							<Sparkles className='text-primary' />
							<h1 className='text-2xl font-bold mb-0'>
								Round # {round.id}
							</h1>
						</div>
						<div className='inline-flex items-center justify-start'>
							<span className='mr-2'>
								<Clock size={18} />
							</span>
							<p>
								Ends in{' '}
								<span>
									<SmallCountdownTimer
										targetDate={round.endTime}
									/>
								</span>
							</p>
						</div>
					</div>
					<div className='flex justify-between items-center flex-wrap'>
						<div>
							<p className='text-gray-400'>
								Estimated Prize Pool
							</p>
							<p className='text-3xl font-bold'>
								<EtherLabel label={round.prize} />
							</p>
						</div>
						<div className='text-right'>
							<p className='text-gray-400'>Ticket Price</p>
							{ticketPrice ? (
								<p className='text-xl font-semibold'>
									<EtherLabel label={ticketPrice} />
								</p>
							) : ticketPriceError ? (
								<p className='error'>There is an error</p>
							) : (
								<Loading />
							)}
						</div>
					</div>
				</>
			) : error ? (
				<p className='error'>There is an error</p>
			) : (
				<Loading />
			)}
		</header>
	);
}
