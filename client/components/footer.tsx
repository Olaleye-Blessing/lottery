export default function Footer() {
	return (
		<footer className='mt-8 border-t border-gray-800 py-8'>
			<div className='container mx-auto px-4 text-center text-gray-400'>
				<p>© {new Date().getFullYear()} Leto. All rights reserved.</p>
			</div>
		</footer>
	);
}
