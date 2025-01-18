import axios from 'axios';
import { clientEnv } from '@/constants/env/client';

export const useLetoInstance = () => {
	const letoInstance = () => {
		const instance = axios.create({
			baseURL: `${clientEnv.NEXT_PUBLIC_BACKEND_URL}/api/v1`,
			withCredentials: true,
		});

		return instance;
	};

	return { letoInstance };
};
