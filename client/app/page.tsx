import CurrentPool from './_home/components/current-pool';
import Header from './_home/components/header';
import Why from './_home/components/why';

export default function Home() {
	return (
		<div className='layout'>
			<Header />
			<main>
				<CurrentPool />
				<Why />
			</main>
		</div>
	);
}
