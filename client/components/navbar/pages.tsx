import { pages } from './utls';
import PageLink from './page';

const _pages = [...pages];

export default function Pages() {
	return (
		<ul className='px-4 md:flex md:space-x-4'>
			{_pages.map((page) => {
				return (
					<li key={page.path} className='my-4 md:my-0'>
						<PageLink page={page} />
					</li>
				);
			})}
		</ul>
	);
}
