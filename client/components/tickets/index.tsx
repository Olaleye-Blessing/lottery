'use client';

import LotteryBall from '@/components/ball';
import { ITicket, IUpdateTicketStatus } from '@/interfaces/ticket';
import { IRound, RoundStatus } from '@/utils/construct-round';
import RegisterTicket from '@/components/register-ticket';
import ClaimTicket from '../claim-ticket';
import StatusLabel from '../status-label';
import { useState } from 'react';

interface PlayerTicketsProps {
	tickets: readonly ITicket[];
	ids: readonly bigint[];
	round: IRound;
	showRoundStatus?: boolean;
}

export default function PlayerTickets({
	tickets: _tickets,
	ids,
	round,
	showRoundStatus = false,
}: PlayerTicketsProps) {
	const [tickets, setTickets] = useState([..._tickets]);

	const updateTicket = (id: bigint, status: IUpdateTicketStatus) => {
		setTickets((prev) => {
			const ticketId = [...ids].findIndex((_id) => _id === id);

			if (id < 0) return prev;

			const newTickects = [...prev];

			newTickects[ticketId] = { ...newTickects[ticketId], ...status };

			return newTickects;
		});
	};

	return (
		<ul>
			{tickets.map((ticket, index) => {
				const ticketId = ids[index];

				return (
					<li
						key={ticketId}
						className='flex items-center justify-between bg-gray-700 p-3 rounded-lg mb-4'
					>
						<div>
							<div className='flex items-center justify-center flex-wrap gap-2'>
								{ticket.numbers.map((num) => {
									const higlighted =
										round?.winningNumbers.includes(num);

									return (
										<LotteryBall
											key={num}
											number={num}
											highlighted={higlighted}
										/>
									);
								})}
							</div>
							{showRoundStatus && (
								<StatusLabel
									status={round.status}
									className='text-sm mt-2'
								/>
							)}
						</div>
						{round.status ===
							RoundStatus.RegisterWinningTickets && (
							<RegisterTicket
								id={ticketId}
								round={round}
								ticket={ticket}
								updateTicket={updateTicket}
							/>
						)}
						{round.status === RoundStatus.Claimable && (
							<ClaimTicket
								id={ticketId}
								round={round}
								ticket={ticket}
								updateTicket={updateTicket}
							/>
						)}
					</li>
				);
			})}
		</ul>
	);
}
