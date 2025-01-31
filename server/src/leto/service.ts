import { formatEther, parseAbiItem } from 'viem';
import { publicClient } from '../configs/viem';
import { redisClient } from '../dbs/redis';
import { letoConfig } from './utils/contract-config';
import { envVars } from '../utils/env-data';
import { LETO_ADRESS } from '../constants/contracts';
import { letoAbi, roundClaimableEvent } from './utils/abi';
import { RoundStatus, IRound, statuses } from './interfaces';

export class LetoService {
  private static readonly CACHE_KEYS = {
    ticketPrize: 'leto_ticket_prize',
    previousRounds: 'leto_previous_rounds',
  };

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

  public static async getPreviousRounds() {
    try {
      const cachedRounds = await redisClient.get(
        this.CACHE_KEYS.previousRounds,
      );

      const rounds: IRound[] = cachedRounds ? JSON.parse(cachedRounds) : [];

      return rounds;
    } catch (error) {
      console.log(error);
      throw Error('Internal Server error');
    }
  }

  public static async listenToRoundsCompletedEvent() {
    const fromBlock = envVars.LETO_DEPLOYMENT_BLOCK;

    publicClient.watchEvent({
      address: LETO_ADRESS,
      fromBlock: BigInt(fromBlock),
      event: parseAbiItem(roundClaimableEvent),
      onLogs: async ([{ args }]) => {
        const round = args.round;
        if (!round) return;

        const roundDetail = await publicClient.readContract({
          address: LETO_ADRESS,
          abi: letoAbi,
          functionName: 'getRoundData',
          args: [round],
        });

        const _round: IRound = {
          id: +roundDetail.id.toString(),
          startTime: +roundDetail.startTime.toString(),
          endTime: +roundDetail.endTime.toString(),
          registerWinningTicketTime:
            +roundDetail.registerWinningTicketTime.toString(),
          prize: +roundDetail.prize.toString(),
          totalTickets: +roundDetail.totalTickets.toString(),
          totalWinningTickets: +roundDetail.totalWinningTickets.toString(),
          // @ts-expect-error Correct
          winningNumbers: roundDetail.winningNumbers.map((n) => +n),
          status: statuses[roundDetail.status as RoundStatus],
        };

        const cachedPrevRoundsStr = await redisClient.get(
          this.CACHE_KEYS.previousRounds,
        );

        const prevRounds: IRound[] = cachedPrevRoundsStr
          ? JSON.parse(cachedPrevRoundsStr)
          : [];

        prevRounds.unshift(_round);

        await redisClient.set(
          this.CACHE_KEYS.previousRounds,
          JSON.stringify(prevRounds),
        );
      },
    });
  }
}
