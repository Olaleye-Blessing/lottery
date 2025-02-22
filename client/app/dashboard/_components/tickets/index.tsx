'use client';

import Loading from '@/app/loading';
import PlayerTickets from '@/components/tickets';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { letoConfig } from '@/configs/leto-contract-config';
import { useGetRound } from '@/hooks/use-get-round';
import { useState } from 'react';
import { Address } from 'viem';
import { useReadContract } from 'wagmi';

export default function Tickets({ player }: { player: Address }) {
	const { data: currentRound, error: currentRoundError } = useReadContract({
		...letoConfig,
		functionName: 'currentRound',
	});
	const [roundId, setRoundId] = useState<number | undefined>(undefined);

	const { round } = useGetRound({
		roundId,
		enabled: currentRound !== undefined,
	});

	const {
		data,
		isFetching: ticketsFetching,
		error: ticketsError,
	} = useReadContract({
		...letoConfig,
		functionName: 'getPlayerTickets',
		args: roundId !== undefined ? [BigInt(roundId)] : undefined,
		account: player,
	});

	const [ticketIDs = [], tickets = []] = data || [];

	return (
		<section className='bg-gray-800/50 rounded-lg mt-8 p-6 backdrop-blur-sm'>
			<header>
				<h1>
					<span>Tickets </span> (
					<span className='text-primary'>
						#{roundId || currentRound?.toString()}
					</span>
					)
				</h1>
			</header>
			<form
				onSubmit={(e) => {
					e.preventDefault();
					// @ts-expect-error Correct
					const round = e.currentTarget.elements.round.value;

					if (round === '') return;

					const roundId = +round;
					if (Number.isNaN(roundId)) return;

					setRoundId(roundId);
				}}
			>
				<div className='flex items-center justify-start flex-wrap'>
					<label className='mr-2 flex-shrink-0 mb-1'>Round ID</label>
					<Input
						className='w-full max-w-[17rem] mr-2 mb-1'
						type='number'
						min={0}
						max={currentRound?.toString()}
						name='round'
						placeholder={
							currentRound !== undefined
								? `Provide round ID up to ${currentRound.toString()}`
								: currentRoundError
								? 'Error getting current round'
								: 'Loading...'
						}
						disabled={currentRound === undefined}
					/>
					<Button type='submit'>Get Tickets</Button>
				</div>
				<output className='mt-7 block'>
					{data && round ? (
						<>
							{tickets.length === 0 ? (
								<p className=''>No tickets yet</p>
							) : (
								<PlayerTickets
									tickets={tickets}
									ids={ticketIDs}
									round={round}
									showRoundStatus
								/>
							)}
						</>
					) : ticketsError ? (
						<p>There is an error getting your tickets</p>
					) : ticketsFetching ? (
						<Loading />
					) : null}
				</output>
			</form>
		</section>
	);
}
