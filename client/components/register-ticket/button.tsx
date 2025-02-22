"use client";

import { useConfirmTx } from "@/hooks/use-confrim-transaction";
import { Button } from "../ui/button";
import { useWriteContract } from "wagmi";
import toast from "react-hot-toast";
import { letoConfig } from "@/configs/leto-contract-config";
import { ITicket } from "@/interfaces/ticket";
import { IRound } from "@/utils/construct-round";
import { formatErrMsg } from "./format-err-msg";
import { useState } from "react";

export interface RegisterTicketButtonProps {
	ticket: ITicket;
	id: bigint;
	round: IRound;
}

export default function RegisterTicketButton({
	ticket,
	id,
	round,
}: RegisterTicketButtonProps) {
	const { writeContractAsync } = useWriteContract();
	const { confrimHash } = useConfirmTx();
	const [registering, setRegistering] = useState(false);

	const regiter = async () => {
		if (ticket.resgistered)
			return toast.error("Ticket has been registered");

		const toastId = toast.loading("Registering your ticket");
		setRegistering(true);

		try {
			const txHash = await writeContractAsync({
				...letoConfig,
				functionName: "registerWinningTicket",
				args: [BigInt(round.id), id],
			});
			toast.loading("Confirming transaction hash", { id: toastId });

			await confrimHash({ txHash });

			toast.success(
				"Ticket Regsitered. You can claim your prize any time from now.",
				{ id: toastId }
			);
		} catch (error) {
			const msg = formatErrMsg(error);

			toast.error(msg, { id: toastId });
		} finally {
			setRegistering(false);
		}
	};

	if (ticket.resgistered) return null;

	return (
		<Button type="button" disabled={registering} onClick={regiter}>
			{ticket.resgistered ? "Claim" : "Register"}
		</Button>
	);
}
