import express from 'express';
import * as letoController from './controller';

const router = express.Router();

router.get('/tickets/price', letoController.getLetoTicketPrice);

export default router;
