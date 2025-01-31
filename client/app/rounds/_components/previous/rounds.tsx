import LotteryBall from '@/components/ball';
import EtherLabel from '@/components/ether-label';
import { IRound } from '@/utils/construct-round';
import Period from '../header/period';

export interface IServerRound extends IRound {
	totalWinningTickets: number;
	winningNumbers: [number, number, number, number, number, number];
}

export default function Rounds({ rounds }: { rounds: IServerRound[] }) {
	return (
		<ul>
			{rounds.map((round) => {
				return (
					<li
						key={round.id}
						className='p-4 bg-gray-900/50 rounded-lg mb-6 last:mb-0'
					>
						<div className='flex items-center justify-between'>
							<p className='h3'>Round #{round.id}</p>
							<EtherLabel
								label={round.prize}
								className='text-muted-foreground'
								iconClassName='text-[1.3em]'
							/>
						</div>
						<div className='my-2 flex items-center justify-between md:justify-start'>
							{round.winningNumbers.map((num) => (
								<LotteryBall
									key={num}
									number={num}
									highlighted
								/>
							))}
						</div>
						<div className='flex flex-wrap justify-between'>
							<div className='mr-2 my-2'>
								<p className=''>Winners</p>
								<p className='text-muted-foreground/80 font-medium'>
									{round.totalWinningTickets}
								</p>
							</div>
							<Period
								label='Start Time'
								date={round.startTime}
								className='mr-2 my-2'
							/>
							<Period
								label='End Time'
								date={round.endTime}
								className='my-2'
							/>
						</div>
					</li>
				);
			})}
		</ul>
	);
}
