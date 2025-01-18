import { Trash2 } from 'lucide-react';
import Digit from './digit';

export type ITickets = { [key: PropertyKey]: number[] };

interface TicketsProps {
	tickets: ITickets;
	onDeleteTicket: (ticketId: number) => void;
}

export default function Tickets({ tickets, onDeleteTicket }: TicketsProps) {
	return (
		<ul className='sm:flex sm:items-center sm:justify-start sm:flex-wrap md:max-h-[24.5rem] md:overflow-y-auto'>
			{Object.entries(tickets).map(([key, tickeNumbers]) => {
				return (
					<li
						key={key}
						className='border border-border rounded-md relative px-3 py-2 my-2 sm:mr-3 sm:my-3 md:flex-1 md:max-w-max lg:max-w-[50%]'
					>
						<button
							type='button'
							onClick={() => onDeleteTicket(+key)}
							className='text-red-600 absolute right-[-0.7rem] top-[-1.5rem] translate-y-1/2 text-sm'
						>
							<Trash2 />
						</button>
						<div className='flex items-center justify-center flex-wrap md:flex-nowrap'>
							{tickeNumbers.map((num) => {
								return <Digit key={num} value={num} />;
							})}
						</div>
					</li>
				);
			})}
		</ul>
	);
}
