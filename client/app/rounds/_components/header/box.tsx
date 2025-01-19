import { ReactNode } from 'react';

interface BoxProps {
	label: string;
	value: ReactNode;
}

export default function Box({ label, value }: BoxProps) {
	return (
		<li className='bg-muted shadow flex flex-col items-center justify-center text-center py-8 px-4 rounded-md w-full max-w-80 my-4 sm:my-2 sm:mr-4 sm:last:mr-0'>
			<p className='text-xl font-bold mb-2'>{label}</p>
			<p className='text-lg'>{value}</p>
		</li>
	);
}
