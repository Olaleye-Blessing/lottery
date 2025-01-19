'use client';

import Loading from '@/app/loading';
import { humanReadAbleDate } from '@/utils/dates';
import Box from './box';
import EtherLabel from '@/components/ether-label';
import { useLetoRequest } from '@/hooks/use-leto-request';
import { useGetRound } from '@/hooks/use-get-round';

export default function Header() {
	const { data: letoPrice, error: letoPriceError } = useLetoRequest<{
		price: number;
	}>({
		url: '/leto/tickets/price',
		options: { queryKey: ['leto', 'ticket-price'] },
	});

	const { round, error } = useGetRound();

	return (
		<header className='flex flex-col text-center sm:flex-row sm:items-center sm:justify-center'>
			<Box
				label='Ticket Prize'
				value={
					letoPrice ? (
						<EtherLabel label={letoPrice.price} />
					) : letoPriceError ? (
						'There is an error fetching price'
					) : (
						<Loading />
					)
				}
			/>
			<Box
				label='Pool Prize'
				value={
					round ? (
						<EtherLabel label={round.prize} />
					) : error ? (
						'There is an error'
					) : (
						<Loading />
					)
				}
			/>
			<Box
				label='Round Ends'
				value={
					round ? (
						humanReadAbleDate({
							date: round.endTime,
							options: {
								hour: '2-digit',
								minute: '2-digit',
								second: '2-digit',
							},
						})
					) : error ? (
						'There is an error'
					) : (
						<Loading />
					)
				}
			/>
		</header>
	);
}
