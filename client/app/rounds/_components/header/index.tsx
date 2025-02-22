'use client';

import Loading from '@/app/loading';
import { useGetRound } from '@/hooks/use-get-round';
import LotteryBall from '@/components/ball';
import EtherLabel from '@/components/ether-label';
import CountdownTimer from '@/components/countdown-timer';
import Period from './period';
import Link from 'next/link';
import { buttonVariants } from '@/components/ui/button';
import { RoundStatus, statuses } from '@/utils/construct-round';

export default function Header() {
	const { round, error } = useGetRound();

	return (
		<header className='my-8'>
			{round ? (
				<div className='bg-gray-800/50 rounded-lg mt-8 p-6 backdrop-blur-sm'>
					<div className='mb-6'>
						<div className='flex justify-between items-start mb-4'>
							<div>
								<h2 className='text-gray-200 text-xl font-semibold'>
									Current Round #{round.id}
								</h2>
							</div>
							<div className='text-gray-400'>
								<p className='text-gray-200 font-semibold'>
									<EtherLabel
										label={round.prize}
										className='text-muted-foreground'
										iconClassName='text-[1.2em]'
									/>
								</p>
							</div>
						</div>
						<CountdownTimer targetDate={round.endTime} />
						<div className='my-4 flex flex-wrap justify-between sm:mx-auto sm:max-w-max'>
							<Period
								label='Start Time'
								date={round.startTime}
								className='mr-4'
							/>
							<Period
								label='End Time'
								date={round.endTime}
								className='mr-4'
							/>
							<div>
								<p>Status</p>
								<p className='text-muted-foreground/80 font-medium'>
									{statuses[round.status]}
								</p>
							</div>
						</div>
					</div>
					<div className='flex gap-3 mb-4 flex-wrap justify-start sm:justify-between sm:max-w-96 sm:mx-auto'>
						{round.status >= RoundStatus.RegisterWinningTickets ? (
							<>
								{round.winningNumbers.map((num) => (
									<LotteryBall key={num} number={num} />
								))}
							</>
						) : (
							<>
								<LotteryBall number={'empty'} />
								<LotteryBall number={'empty'} />
								<LotteryBall number={'empty'} />
								<LotteryBall number={'empty'} />
								<LotteryBall number={'empty'} />
							</>
						)}
					</div>
					{Date.now() < round.endTime && (
						<div className='flex items-center justify-center mt-4'>
							<Link
								className={buttonVariants({
									className: 'w-full max-w-max',
								})}
								href='/buy-ticket'
							>
								Buy Ticket
							</Link>
						</div>
					)}
				</div>
			) : error ? (
				<p className='error'>There is an error</p>
			) : (
				<Loading />
			)}
		</header>
	);
}
