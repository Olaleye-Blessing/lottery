import { formatEther } from 'viem';
import { publicClient } from '../configs/viem';
import { redisClient } from '../dbs/redis';
import { letoConfig } from './utils/contract-config';

export class LetoService {
  public static async getTicketPrice(): Promise<{ price: number }> {
    const cachedKey = 'leto_ticket_prize';

    try {
      const cachedPrize = await redisClient.get(cachedKey);

      if (cachedPrize) {
        return { price: +JSON.parse(cachedPrize) };
      }

      const bigPrice = await publicClient.readContract({
        ...letoConfig,
        functionName: 'ticketPrice',
      });

      const price = formatEther(bigPrice);

      await redisClient.set(cachedKey, price);

      return { price: +price };
    } catch (error) {
      console.log(error);
      throw Error('Internal server error');
    }
  }
}
