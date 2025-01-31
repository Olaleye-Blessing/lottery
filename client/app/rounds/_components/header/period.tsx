import { humanReadAbleDate } from '@/utils/dates';

interface PeriodProps {
	label: string;
	date: number;
	className?: string;
}

export default function Period({ label, date, className }: PeriodProps) {
	return (
		<div className={className}>
			<p>{label}</p>
			<p className='text-muted-foreground/80 font-medium'>
				{humanReadAbleDate({
					date,
					options: {
						year: 'numeric',
						month: 'short',
						day: 'numeric',
						hour: 'numeric',
						minute: 'numeric',
						second: 'numeric',
						weekday: 'short',
					},
				})}
			</p>
		</div>
	);
}
