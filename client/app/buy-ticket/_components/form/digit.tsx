import { cn } from '@/lib/utils';

interface DigitProps {
	value: number;
	onClick?: (num: number) => void;
	className?: string;
}

export default function Digit({ value, className, onClick }: DigitProps) {
	return (
		<button
			type='button'
			className={cn(
				'w-8 h-8 rounded-full flex items-center justify-center text-center border-border border-2 p-4 m-1 transition-colors duration-300',
				className
			)}
			onClick={() => onClick?.(value)}
		>
			{value}
		</button>
	);
}
