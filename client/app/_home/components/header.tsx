import { ArrowRight } from 'lucide-react';
import Link from 'next/link';

export default function Header() {
	return (
		<header className='container mx-auto px-4 py-16 md:py-24'>
			<div className='text-center max-w-4xl mx-auto'>
				<h1 className='text-4xl md:text-6xl font-bold mb-6'>
					The Future of
					<span className='bg-gradient-to-r from-purple-500 to-blue-500 bg-clip-text text-transparent'>
						{' '}
						Decentralized{' '}
					</span>
					Lottery
				</h1>
				<p className='text-gray-400 text-lg md:text-xl mb-8'>
					Transparent, fair, and unstoppable. Join thousands of
					players worldwide in the most trusted blockchain lottery.
				</p>
				<div className='flex flex-col md:flex-row gap-4 justify-center items-center'>
					<Link
						href='/buy-ticket'
						className='w-full md:w-auto bg-purple-600 hover:bg-purple-700 px-8 py-3 rounded-lg text-lg font-semibold transition-colors flex items-center justify-center gap-2'
					>
						Play Now <ArrowRight size={20} />
					</Link>
				</div>
			</div>
		</header>
	);
}
