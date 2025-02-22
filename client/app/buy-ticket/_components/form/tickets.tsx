import { Trash2 } from 'lucide-react';

export type ITickets = { [key: PropertyKey]: number[] };
interface TicketsProps {
	tickets: ITickets;
	onDeleteTicket: (ticketId: number) => void;
}

export default function Tickets({ tickets, onDeleteTicket }: TicketsProps) {
	return (
		<ul className='max-h-[24.2rem] overflow-y-auto'>
			{Object.entries(tickets).map(([key, tickeNumbers]) => {
				return (
					<li
						key={key}
						className='flex items-center justify-between bg-gray-700 p-3 rounded-lg mb-4'
					>
						<div className='flex items-center justify-center flex-wrap gap-2'>
							{tickeNumbers.map((num) => {
								return (
									<span
										key={num}
										className='w-8 h-8 flex items-center justify-center bg-primary rounded-full'
									>
										{num}
									</span>
								);
							})}
						</div>
						<button
							onClick={() => onDeleteTicket(+key)}
							className='text-gray-400 hover:text-red-600 transition-colors'
						>
							<Trash2 size={18} />
						</button>
					</li>
				);
			})}
		</ul>
	);
}
