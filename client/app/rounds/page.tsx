import Header from './_components/header';
import PreviousRounds from './_components/previous';
import UserTickets from './_components/user-tickets';

export default function RoundsPage() {
	return (
		<div className='layout'>
			<Header />
			<UserTickets />
			<PreviousRounds />
		</div>
	);
}
