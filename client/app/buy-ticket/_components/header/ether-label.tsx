import Ether from '@/components/svgs/ether';

export default function EtherLabel({ label }: { label: number | string }) {
	return (
		<span className='inline-flex items-center justify-center'>
			<span className='mr-0.5'>{label}</span>
			<span className='text-xl'>
				<Ether />
			</span>
		</span>
	);
}
