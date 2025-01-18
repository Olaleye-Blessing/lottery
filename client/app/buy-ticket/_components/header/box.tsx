import { ReactNode } from 'react';

interface BoxProps {
	label: string;
	value: ReactNode;
}

export default function Box({ label, value }: BoxProps) {
	return (
		<div className='mb-3 sm:mb-0 sm:mr-3 sm:last:mr-0 md:mr-6'>
			<p className='font-bold text-2xl'>{label}</p>
			<div>
				<p className='text-lg text-primary'>{value}</p>
			</div>
		</div>
	);
}
