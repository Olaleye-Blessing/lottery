'use client';

export default function Hamburger() {
	return (
		<button
			className='hamburger'
			onClick={(e) => {
				e.currentTarget.classList.toggle('active');
			}}
		>
			<span className='bar'></span>
			<span className='bar'></span>
			<span className='bar'></span>
		</button>
	);
}
