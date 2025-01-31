import { cn } from '@/lib/utils';

interface TimeUnitProps {
	value: number;
	label: string;
	animate: boolean;
}

export default function TimeUnit({ value, label, animate }: TimeUnitProps) {
	return (
		<div className='flex flex-col items-center p-4'>
			<div
				className={cn(
					'font-bold bg-primary/60 text-white rounded-lg flex items-center justify-center transform transition-all duration-200',
					'text-lg w-8 h-8 sm:text-2xl sm:w-12 sm:h-12 md:text-4xl md:w-16 md:h-16',
					animate ? 'scale-110 bg-primary/70' : 'scale-100'
				)}
			>
				<span
					className={`
          transition-opacity duration-200 
          ${animate ? 'opacity-0' : 'opacity-100'}
        `}
				>
					{String(value).padStart(2, '0')}
				</span>
			</div>
			<div className='text-sm mt-2 text-gray-600'>{label}</div>
		</div>
	);
}
