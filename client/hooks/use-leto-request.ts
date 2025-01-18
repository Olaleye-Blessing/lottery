import { useQuery, UseQueryOptions } from '@tanstack/react-query';
import { useLetoInstance } from './use-leto-instance';
import { parseLetoApiError } from '@/utils/parse-leto-api-error';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const useLetoRequest = <TData = any, TError = any>({
	url,
	options,
}: {
	url: string;
	options: UseQueryOptions<TData, TError>;
}) => {
	const { letoInstance } = useLetoInstance();
	const result = useQuery({
		...options,
		queryFn: async () => {
			try {
				const { data } = await letoInstance().get<{ data: TData }>(url);

				return data.data;
			} catch (error) {
				throw new Error(parseLetoApiError(error));
			}
		},
	});

	return result;
};
