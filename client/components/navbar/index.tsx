import Link from 'next/link';
import './index.css';
import Wallet from './wallet';
import Pages from './pages';
import Hamburger from './hamburger';

export default function Navbar() {
	return (
		<nav className='py-2 border border-border sticky top-0 left-0 z-[49] bg-background shadow-2xl'>
			<div className='layout flex items-center justify-between'>
				<div className='mr-1'>
					<Link href={'/'}>Logo</Link>
				</div>
				<Hamburger />
				<div className='nav__contents'>
					<Pages />
				</div>
				<Wallet />
			</div>
		</nav>
	);
}
