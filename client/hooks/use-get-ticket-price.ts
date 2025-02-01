import { useLetoRequest } from './use-leto-request';

export const useGetTicketPrice = () => {
	const {
		data,
		error: ticketPriceError,
		isFetching: isFetchingTicketPrice,
		...result
	} = useLetoRequest<{
		price: number;
	}>({
		url: '/leto/tickets/price',
		options: { queryKey: ['leto', 'ticket-price'] },
	});

	return {
		ticketPrice: data?.price,
		ticketPriceError,
		isFetchingTicketPrice,
		...result,
	};
};
