import { RoundStatus, statuses } from '@/utils/construct-round';
import {
	Tooltip,
	TooltipContent,
	TooltipProvider,
	TooltipTrigger,
} from '@/components/ui/tooltip';

export default function StatusLabel({
	status,
	className,
}: {
	status: RoundStatus;
	className?: string;
}) {
	const _status = statuses[status];

	return (
		<TooltipProvider>
			<Tooltip>
				<TooltipTrigger className={className}>
					<span
						className={`inline-flex items-center rounded-md px-2 py-1 text-sm font-medium ring-1 ring-inset ${_status.color}`}
					>
						{_status.label}
					</span>
				</TooltipTrigger>
				<TooltipContent>
					<p className='max-w-xs'>{_status.info}</p>
				</TooltipContent>
			</Tooltip>
		</TooltipProvider>
	);
}
