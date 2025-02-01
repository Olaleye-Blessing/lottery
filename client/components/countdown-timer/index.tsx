import { useState, useEffect } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import TimeUnit from './time-unit';

export default function CountdownTimer({
	targetDate,
}: {
	targetDate: string | number;
}) {
	const [timeLeft, setTimeLeft] = useState({
		days: 0,
		hours: 0,
		minutes: 0,
		seconds: 0,
	});

	const [animations, setAnimations] = useState({
		days: false,
		hours: false,
		minutes: false,
		seconds: false,
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

			setTimeLeft((prevTime) => {
				const newAnimations = {
					days: prevTime.days !== days,
					hours: prevTime.hours !== hours,
					minutes: prevTime.minutes !== minutes,
					seconds: prevTime.seconds !== seconds,
				};

				if (Object.values(newAnimations).some(Boolean)) {
					setAnimations(newAnimations);
					// Reset animations after delay
					setTimeout(() => {
						setAnimations({
							days: false,
							hours: false,
							minutes: false,
							seconds: false,
						});
					}, 100);
				}

				return { days, hours, minutes, seconds };
			});
		};

		calculateTimeLeft();
		const timer = setInterval(calculateTimeLeft, 1000);

		return () => clearInterval(timer);
	}, [targetDate]);

	return (
		<Card className='w-full max-w-2xl mx-auto'>
			<CardContent className='p-0'>
				<div className='py-4 flex justify-center items-center flex-wrap'>
					<TimeUnit
						animate={animations.days}
						value={timeLeft.days}
						label='Days'
					/>
					<TimeUnit
						animate={animations.hours}
						value={timeLeft.hours}
						label='Hours'
					/>
					<TimeUnit
						animate={animations.minutes}
						value={timeLeft.minutes}
						label='Minutes'
					/>
					<TimeUnit
						animate={animations.seconds}
						value={timeLeft.seconds}
						label='Seconds'
					/>
				</div>
			</CardContent>
		</Card>
	);
}
