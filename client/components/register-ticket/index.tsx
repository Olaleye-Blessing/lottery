import { RoundStatus } from '@/utils/construct-round';
import RegisterTicketButton, { type RegisterTicketButtonProps } from './button';
import { ILotteryNumber } from '@/interfaces/ticket';

type RegisterTicketProps = RegisterTicketButtonProps;

export const numbersEqual = (
	ticketNum: ILotteryNumber,
	roundNum: ILotteryNumber
) =>
	JSON.stringify([...ticketNum].sort()) ===
	JSON.stringify([...roundNum].sort());

export default function RegisterTicket({
	id,
	round,
	ticket,
}: RegisterTicketProps) {
	if (ticket.resgistered) return <p className='text-sm'>Registered</p>;

	const showRegisterBtn =
		round.status === RoundStatus.RegisterWinningTickets &&
		!ticket.resgistered &&
		numbersEqual(ticket.numbers, round.winningNumbers);

	if (!showRegisterBtn) return null;

	return <RegisterTicketButton id={id} round={round} ticket={ticket} />;
}
