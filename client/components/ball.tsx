import { cn } from '@/lib/utils';

interface LotteryBallProps {
	number: number | 'empty';
	highlighted?: boolean;
}

export default function LotteryBall({
	number,
	highlighted = false,
}: LotteryBallProps) {
	return (
		<div
			className={cn(
				'w-10 h-10 rounded-full flex items-center justify-center shadow-lg font-bold text-xl md:w-12 md:h-12',
				highlighted
					? 'bg-gradient-to-br from-primary/40 to-primary/60 text-black'
					: 'bg-gradient-to-br from-gray-700 to-gray-900 text-white'
			)}
		>
			{number === 'empty' ? '-' : number.toString().padStart(2, '0')}
		</div>
	);
}
