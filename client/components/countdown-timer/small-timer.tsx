import { cn } from '@/lib/utils';
import { useState, useEffect } from 'react';

interface SmallCountdownTimerProps {
	targetDate: string | number;
	className?: string;
}

export default function SmallCountdownTimer({
	targetDate,
	className,
}: SmallCountdownTimerProps) {
	const [timeLeft, setTimeLeft] = useState({
		days: 0,
		hours: 0,
		minutes: 0,
		seconds: 0,
	});

	useEffect(() => {
		const calculateTimeLeft = () => {
			const difference =
				new Date(targetDate).getTime() - new Date().getTime();

			if (difference < 0) return;

			const days = Math.floor(difference / (1000 * 60 * 60 * 24));
			const hours = Math.floor(
				(difference % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)
			);
			const minutes = Math.floor(
				(difference % (1000 * 60 * 60)) / (1000 * 60)
			);
			const seconds = Math.floor((difference % (1000 * 60)) / 1000);

			setTimeLeft(() => {
				return { days, hours, minutes, seconds };
			});
		};

		calculateTimeLeft();
		const timer = setInterval(calculateTimeLeft, 1000);

		return () => clearInterval(timer);
	}, [targetDate]);

	const closeToZero =
		timeLeft.days === 0 &&
		timeLeft.hours === 0 &&
		timeLeft.minutes === 0 &&
		timeLeft.seconds < 59;

	return (
		<div
			className={cn(
				className,
				'inline-flex items-center justify-start max-w-max',
				closeToZero && 'text-red-700'
			)}
		>
			<p>{timeLeft.days}:</p>
			<p>{timeLeft.hours}:</p>
			<p>{timeLeft.minutes}:</p>
			<p>{timeLeft.seconds}</p>
		</div>
	);
}
