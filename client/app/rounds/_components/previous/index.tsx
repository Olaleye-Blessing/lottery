'use client';

import Loading from '@/app/loading';
import { useLetoRequest } from '@/hooks/use-leto-request';
import Rounds, { IServerRound } from './rounds';

export default function PreviousRounds() {
	const { data, isFetching, error } = useLetoRequest<IServerRound[]>({
		url: `/leto/rounds/prev`,
		options: { queryKey: ['leto', 'rounds', 'prev'] },
	});

	return (
		<section className='bg-card my-4'>
			<header>
				<h2>Previous Rounds</h2>
			</header>

			<div>
				{data ? (
					<>
						{data.length === 0 ? (
							<p>There are no previous rounds</p>
						) : (
							<Rounds rounds={data} />
						)}
					</>
				) : error ? (
					<p className='error'>There is an error</p>
				) : isFetching ? (
					<Loading />
				) : null}
			</div>
		</section>
	);
}
