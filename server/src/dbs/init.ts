import { connectRedisDB } from './redis';

export const connectDBs = async () => {
  await Promise.allSettled([connectRedisDB()]);
};
