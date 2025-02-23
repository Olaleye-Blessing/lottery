"use client";

import { useConfirmTx } from "@/hooks/use-confrim-transaction";
import { Button } from "../ui/button";
import { useWriteContract } from "wagmi";
import toast from "react-hot-toast";
import { letoConfig } from "@/configs/leto-contract-config";
import { ITicket, IUpdateTicketStatus } from "@/interfaces/ticket";
import { IRound } from "@/utils/construct-round";
import { formatErrMsg } from "./format-err-msg";
import { useState } from "react";
import EtherLabel from "../ether-label";


export interface ClaimTicketButtonProps {
	ticket: ITicket;
	id: bigint;
	round: IRound;
	updateTicket: (id: bigint, status: IUpdateTicketStatus) => void;
}

export default function ClaimTicketButton({
	ticket,
	id,
	round,
	updateTicket,
}: ClaimTicketButtonProps) {
	const { writeContractAsync } = useWriteContract();
	const { confrimHash } = useConfirmTx();
	const [claiming, setClaiming] = useState(false);

	const claim = async () => {
		if (ticket.claimed) return toast.error("Ticket has been claimed");

		const toastId = toast.loading("Claiming your ticket");
		setClaiming(true);

		try {
			const txHash = await writeContractAsync({
				...letoConfig,
				functionName: "claimPrize",
				args: [BigInt(round.id), id],
			});
			toast.loading("Confirming transaction hash", { id: toastId });

			await confrimHash({ txHash });

			toast.success("Funds transferred to your wallet!", { id: toastId });
			updateTicket(id, { claimed: true });
		} catch (error) {
			const msg = formatErrMsg(error);

			toast.error(msg, { id: toastId });
		} finally {
			setClaiming(false);
		}
	};

	if (ticket.claimed) return null;

	return (
		<div className="flex flex-col">
			<Button
				type="button"
				disabled={claiming}
				onClick={claim}
				className="mb-1"
			>
				<span>{claiming ? "Claiming" : `Claim`}</span>
			</Button>
			<EtherLabel
				label={round.prize / round.totalWinningTickets}
				iconClassName="text-sm"
			/>
		</div>
	);
}
