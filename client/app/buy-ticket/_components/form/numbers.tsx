'use client';

import { useState } from 'react';
import Digit from './digit';
import { Button } from '@/components/ui/button';
import { RefreshCw } from 'lucide-react';

const _numbers = Array.from({ length: 99 }, (_, index) => index + 1);

const TOTAL_TICKET_NUMBERS = 6;
const MAX_NUMBER = 59;

interface NumbersProps {
	addTicket: (ticketNumbers: number[]) => void;
	creatingTicket: boolean;
}

export default function Numbers({ addTicket, creatingTicket }: NumbersProps) {
	const [selectedNumbers, setSelectedNumbers] = useState<number[]>([]);

	const selectNumber = (num: number) => {
		let newSelectedNumber = [...selectedNumbers];

		const selected = newSelectedNumber.includes(num);

		if (selected) {
			newSelectedNumber = newSelectedNumber.filter((n) => n !== num);
		} else {
			if (newSelectedNumber.length >= TOTAL_TICKET_NUMBERS) return;

			newSelectedNumber.push(num);
		}

		setSelectedNumbers(newSelectedNumber);
	};

	const saveSelectedNumber = () => {
		if (selectedNumbers.length !== TOTAL_TICKET_NUMBERS) return;

		const _selectedNums = [...selectedNumbers].sort((a, b) => a - b);

		addTicket(_selectedNums);

		setSelectedNumbers([]);
	};

	const quickPick = () => {
		const _numbers: Array<number> = [];

		while (_numbers.length < TOTAL_TICKET_NUMBERS) {
			const num = Math.floor(Math.random() * MAX_NUMBER) + 1;

			if (!_numbers.includes(num)) {
				_numbers.push(num);
			}
		}

		setSelectedNumbers(_numbers);
	};

	return (
		<section className='bg-gray-800 rounded-lg p-6 mb-8 sm:w-[48%]'>
			<header className='flex justify-between items-center mb-4 flex-wrap'>
				<h2 className='text-xl font-semibold'>Select 6 Numbers</h2>
				<Button type='button' onClick={quickPick}>
					<RefreshCw size={18} />
					Quick Pick
				</Button>
			</header>
			<div className='flex items-start justify-center flex-wrap'>
				{_numbers.map((num) => (
					<Digit
						key={num}
						value={num}
						onClick={(val) => selectNumber(val)}
						className={
							selectedNumbers.includes(num) ? ' bg-primary' : ''
						}
					/>
				))}
			</div>
			<div className='flex items-center justify-center mt-6'>
				<Button
					type='button'
					className='w-full'
					// variant={'secondary'}
					onClick={saveSelectedNumber}
					disabled={selectedNumbers.length !== 6 || creatingTicket}
				>
					Save
				</Button>
			</div>
		</section>
	);
}
