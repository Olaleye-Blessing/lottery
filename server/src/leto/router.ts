import express from 'express';
import * as letoController from './controller';

const router = express.Router();

router.get('/tickets/price', letoController.getLetoTicketPrice);
router.get('/rounds/prev', letoController.getLetoPreviousRounds);

export default router;
