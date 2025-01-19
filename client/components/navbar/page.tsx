'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { pages } from './utls';

interface PageLinkProps {
	page: (typeof pages)[number];
}

export default function PageLink({ page }: PageLinkProps) {
	const pathname = usePathname();

	const closeHamburger = () => {
		document.querySelector('.hamburger')?.classList.remove('active');
	};

	return (
		<Link
			href={page.path}
			onClick={closeHamburger}
			className={`block w-full hover:text-primary ${
				pathname === page.path ? 'text-primary' : ''
			}`}
		>
			<span>{page.label}</span>
		</Link>
	);
}
