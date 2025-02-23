import { RoundStatus } from "@/utils/construct-round";
import { ILotteryNumber } from "@/interfaces/ticket";
import ClaimTicketButton, { ClaimTicketButtonProps } from "./button";

type ClaimTicketProps = ClaimTicketButtonProps;

export const numbersEqual = (
	ticketNum: ILotteryNumber,
	roundNum: ILotteryNumber
) =>
	JSON.stringify([...ticketNum].sort()) ===
	JSON.stringify([...roundNum].sort());

	
export default function ClaimTicket({
	id,
	round,
	ticket,
	updateTicket,
}: ClaimTicketProps) {
	if (ticket.claimed)
		return <p className="text-sm text-green-600">Claimed</p>;

	const isClaimingPeriod = round.status === RoundStatus.Claimable;

	if (!isClaimingPeriod) return null;

	const isTicketWon = numbersEqual(ticket.numbers, round.winningNumbers);

	if (!isTicketWon) return null;

	if (!ticket.resgistered)
		return <p className="text-red-500 text-sm">Sorry, not registered.</p>;

	return (
		<ClaimTicketButton
			id={id}
			round={round}
			ticket={ticket}
			updateTicket={updateTicket}
		/>
	);
}
