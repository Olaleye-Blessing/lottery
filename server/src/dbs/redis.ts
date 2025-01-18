import { createClient, RedisClientType } from 'redis';
import { envVars } from '../utils/env-data';

let redisClient: RedisClientType;

const connectRedisDB = async () => {
  redisClient = createClient({ url: envVars.REDIS_URL });
  redisClient.on('error', (err) => console.log('Redis Client Error', err));

  console.log('✅ REDIS DB connection successful');

  await redisClient.connect();
};

export { connectRedisDB, redisClient };
