'use client';

import { useState } from 'react';
import { useConfig, useWriteContract } from 'wagmi';
import { waitForTransactionReceipt } from '@wagmi/core';
import { parseEther } from 'viem';
import toast from 'react-hot-toast';
import { Button } from '@/components/ui/button';
import { letoConfig } from '@/configs/leto-contract-config';
import Numbers from './numbers';
import Tickets, { ITickets } from './tickets';
import { getCreateErrMsg } from '../../_utils/err-msg';
import { useGetTicketPrice } from '@/hooks/use-get-ticket-price';
import EtherLabel from '@/components/ether-label';
import { ShoppingCart } from 'lucide-react';
import { useGetRound } from '@/hooks/use-get-round';
import { RoundStatus } from '@/utils/construct-round';

export default function Form() {
	const { round } = useGetRound();
	const { ticketPrice: letoTicketPrice } = useGetTicketPrice();
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

		const ticketPrice = letoTicketPrice * _totalTickets;

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
		<form>
			<fieldset
				disabled={round?.status !== RoundStatus.Active}
				className='sm:flex sm:items-start sm:justify-between'
			>
				<Numbers
					addTicket={addTicket}
					creatingTicket={creatingTicket}
				/>

				<section className='bg-gray-800 rounded-lg p-6 sm:w-[48%]'>
					<div className='flex items-center gap-2 mb-4'>
						<ShoppingCart />
						<h2 className='text-xl font-semibold'>Your Tickets</h2>
					</div>
					{totalTickets > 0 && (
						<Tickets
							tickets={tickets}
							onDeleteTicket={deleteTicket}
						/>
					)}
					<div className='flex justify-between items-center border-t border-gray-700 pt-2 flex-wrap'>
						<div className='mt-2'>
							<p className='text-gray-400'>Total</p>
							<p className='text-2xl font-bold'>
								<EtherLabel
									label={
										(letoTicketPrice || 0) * totalTickets
									}
								/>
							</p>
						</div>
						<Button
							onClick={(e) => {
								e.preventDefault();
								buyTickets();
							}}
							disabled={totalTickets === 0}
							className={`mt-2 rounded-lg font-semibold ${
								totalTickets > 0
									? ''
									: 'bg-gray-700 text-gray-500 cursor-not-allowed'
							} transition-colors`}
						>
							Purchase Tickets
						</Button>
					</div>
				</section>
			</fieldset>
		</form>
	);
}
