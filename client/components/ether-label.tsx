import Ether from '@/components/svgs/ether';
import { cn } from '@/lib/utils';

interface EtherLabelProps {
	label: number | string;
	iconClassName?: string;
	className?: string;
}

export default function EtherLabel({
	label,
	className,
	iconClassName,
}: EtherLabelProps) {
	return (
		<span
			className={cn('inline-flex items-center justify-center', className)}
		>
			<span className='mr-0.5'>{label}</span>
			<span className={cn('text-xl', iconClassName)}>
				<Ether />
			</span>
		</span>
	);
}
