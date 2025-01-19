'use client';

import Loading from '@/app/loading';
import { useGetRound } from '@/hooks/use-get-round';
import Box from './box';
import { humanReadAbleDate } from '@/utils/dates';
import EtherLabel from '@/components/ether-label';

export default function Header() {
	const { round, error } = useGetRound();

	console.log('__ ROUND ___', round);
	/*
  {
    "id": 0,
    "startTime": 1737200085000,
    "endTime": 1737804885000,
    "prize": 0.022,
    "totalTickets": 11,
    "winningNumbers": [0, 0, 0, 0, 0, 0]
  }
  */

	return (
		<header>
			{round ? (
				<>
					<h1 className='sr-only'>Current round detail</h1>
					<p className='text-center h1 mt-8 mb-4'>
						<span className=''>Pool Prize: </span>
						<EtherLabel
							label={round.prize}
							className='text-[0.7em] text-muted-foreground'
							iconClassName='text-[1.5em]'
						/>
					</p>
					<ul className='flex flex-col items-center justify-center sm:flex-row'>
						<Box label='ID' value={`# ${round.id}`} />
						<Box label='Total Tickets' value={round.totalTickets} />
						<Box
							label='End At'
							// TODO: Change this to a countdown component
							value={humanReadAbleDate({ date: round.endTime })}
						/>
					</ul>
				</>
			) : error ? (
				<p className='error'></p>
			) : (
				<Loading />
			)}
		</header>
	);
}
