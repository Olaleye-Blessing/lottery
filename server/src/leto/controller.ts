import { catchAsync } from '../utils/catch-async';
import { sendResponse } from '../utils/send-response';
import { LetoService } from './service';

export const getLetoTicketPrice = catchAsync(async (_, res) => {
  sendResponse(res, 200, await LetoService.getTicketPrice());
});

export const getLetoPreviousRounds = catchAsync(async (_, res) => {
  sendResponse(res, 200, await LetoService.getPreviousRounds());
});
