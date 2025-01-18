'use client';

import { useState } from 'react';
import Digit from './digit';
import { Button } from '@/components/ui/button';

const _numbers = Array.from({ length: 100 }, (_, index) => index);

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
			if (newSelectedNumber.length >= 6) return;

			newSelectedNumber.push(num);
		}

		setSelectedNumbers(newSelectedNumber);
	};

	const saveSelectedNumber = () => {
		if (selectedNumbers.length !== 6) return;

		const _selectedNums = [...selectedNumbers].sort((a, b) => a - b);

		addTicket(_selectedNums);

		setSelectedNumbers([]);
	};

	return (
		<section>
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
					variant={'secondary'}
					onClick={saveSelectedNumber}
					disabled={selectedNumbers.length !== 6 || creatingTicket}
				>
					Save
				</Button>
			</div>
		</section>
	);
}
