export default function SiteLogo({
	className = 'w-8 h-8',
}: {
	className?: string;
}) {
	return (
		<svg
			className={className}
			xmlns='http://www.w3.org/2000/svg'
			viewBox='0 0 200 200'
		>
			<polygon
				points='100,20 170,60 170,140 100,180 30,140 30,60'
				fill='none'
				stroke='#6d26d8'
				strokeWidth='4'
			/>

			<path
				d='M100,30 L140,100 L100,130 L60,100 L100,30'
				fill='none'
				stroke='#6d26d8'
				strokeWidth='3'
			/>
			<path
				d='M100,70 L140,100 L100,170 L60,100 L100,70'
				fill='none'
				stroke='#6d26d8'
				strokeWidth='3'
			/>

			<circle cx='100' cy='100' r='25' fill='#6d26d8' />
			<text
				x='100'
				y='108'
				textAnchor='middle'
				fill='rgb(249, 250, 251)'
				fontFamily='Arial'
				fontWeight='bold'
				fontSize='24'
			>
				7
			</text>

			<circle cx='30' cy='60' r='4' fill='#6d26d8' />
			<circle cx='30' cy='140' r='4' fill='#6d26d8' />
			<circle cx='100' cy='180' r='4' fill='#6d26d8' />
			<circle cx='170' cy='140' r='4' fill='#6d26d8' />
			<circle cx='170' cy='60' r='4' fill='#6d26d8' />
			<circle cx='100' cy='20' r='4' fill='#6d26d8' />
		</svg>
	);
}
