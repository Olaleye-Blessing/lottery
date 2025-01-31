import { Shield, Ticket, Trophy } from 'lucide-react';

export default function Why() {
	return (
		<>
			<section className='container mx-auto px-4 py-16 grid md:grid-cols-3 gap-8'>
				<div className='bg-gray-800/50 p-6 rounded-xl'>
					<div className='w-12 h-12 bg-purple-600/20 rounded-lg flex items-center justify-center mb-4'>
						<Shield className='text-purple-400' />
					</div>
					<h3 className='text-xl font-semibold mb-2'>
						Secure & Transparent
					</h3>
					<p className='text-gray-400'>
						All transactions and draws are verified on the
						blockchain for complete transparency.
					</p>
				</div>
				<div className='bg-gray-800/50 p-6 rounded-xl'>
					<div className='w-12 h-12 bg-purple-600/20 rounded-lg flex items-center justify-center mb-4'>
						<Ticket className='text-purple-400' />
					</div>
					<h3 className='text-xl font-semibold mb-2'>Fair Play</h3>
					<p className='text-gray-400'>
						Smart contract-powered random number generation ensures
						completely fair results.
					</p>
				</div>
				<div className='bg-gray-800/50 p-6 rounded-xl'>
					<div className='w-12 h-12 bg-purple-600/20 rounded-lg flex items-center justify-center mb-4'>
						<Trophy className='text-purple-400' />
					</div>
					<h3 className='text-xl font-semibold mb-2'>
						Instant Prizes
					</h3>
					<p className='text-gray-400'>
						Winners receive their prizes automatically through smart
						contracts.
					</p>
				</div>
			</section>
		</>
	);
}
