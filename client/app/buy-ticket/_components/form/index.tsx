'use client';

import { useState } from 'react';
import { useConfig, useWriteContract } from 'wagmi';
import { waitForTransactionReceipt } from '@wagmi/core';
import { parseEther } from 'viem';
import toast from 'react-hot-toast';
import { useLetoRequest } from '@/hooks/use-leto-request';
import { Button } from '@/components/ui/button';
import { letoConfig } from '@/configs/leto-contract-config';
import Numbers from './numbers';
import Tickets, { ITickets } from './tickets';
import { getCreateErrMsg } from '../../_utils/err-msg';

export default function Form() {
	const { data: letoTicketPrice } = useLetoRequest<{ price: number }>({
		url: '/leto/tickets/price',
		options: { queryKey: ['leto', 'ticket-price'] },
	});
	const config = useConfig();
	const { writeContractAsync } = useWriteContract();
	const [tickets, setTickets] = useState<ITickets>({});
	const [creatingTicket, setCreatingTicket] = useState(false);

	const addTicket = (ticketNumbers: number[]) => {
		const _tickets = { ...tickets };
		_tickets[Date.now()] = ticketNumbers;

		setTickets(_tickets);
	};

	const deleteTicket = (id: number) => {
		const _newTickets = { ...tickets };

		delete _newTickets[id];

		setTickets(_newTickets);
	};

	const totalTickets = Object.keys(tickets).length;

	const buyTickets = async () => {
		if (!letoTicketPrice) return;

		const _tickets = Object.values(tickets);
		const _totalTickets = _tickets.length;

		if (_totalTickets === 0) return;

		const ticketPrice = letoTicketPrice.price * _totalTickets;

		setCreatingTicket(true);

		const toastId = toast.loading('Creating ticket(s)');

		try {
			const txHash = await writeContractAsync({
				...letoConfig,
				functionName: _totalTickets === 0 ? 'buyTicket' : 'buyTickets',
				// @ts-expect-error Correct
				args: [_tickets],
				value: parseEther(String(ticketPrice)),
			});

			toast.loading('Confirming transaction hash', { id: toastId });

			await waitForTransactionReceipt(config, {
				hash: txHash,
				confirmations: 1,
			});

			toast.success('Ticket(s) created successfully', { id: toastId });
		} catch (error) {
			toast.error(getCreateErrMsg(error), { id: toastId });
		} finally {
			setCreatingTicket(false);
		}
	};

	return (
		<div className='md:flex md:items-start md:justify-between'>
			<form className='mt-4 max-w-[30rem] mx-auto'>
				<Numbers
					addTicket={addTicket}
					creatingTicket={creatingTicket}
				/>
			</form>
			<div className='mt-4 w-full'>
				<section>
					<header>
						<h2>
							<span>Total Tickets: </span>
							<span className='text-primary'>{totalTickets}</span>
						</h2>
					</header>
					{totalTickets > 0 && (
						<Tickets
							tickets={tickets}
							onDeleteTicket={deleteTicket}
						/>
					)}
				</section>
				{totalTickets > 0 && (
					<div className='flex items-center justify-center mt-8'>
						<Button
							type='button'
							onClick={() => buyTickets()}
							disabled={!letoTicketPrice || creatingTicket}
							isLoading={creatingTicket}
						>
							Buy Tickets
						</Button>
					</div>
				)}
			</div>
		</div>
	);
}
