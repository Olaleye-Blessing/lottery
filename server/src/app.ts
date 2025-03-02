import express from 'express';
import morgan from 'morgan';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import { envVars } from './utils/env-data';
import { globalErrorHanlder } from './utils/errors/global-err-handler';
import letoRoute from './leto/router';

const app = express();

if (envVars.NODE_ENV !== 'production') app.use(morgan('dev'));

const allowedOrigins = envVars.ALLOWED_ORIGINS.split(',').map((origin) => {
  if (!origin.startsWith('/')) return origin;

  return new RegExp(origin.slice(1, -1));
});

app.use(cors({ origin: allowedOrigins, credentials: true }));

app.use(cookieParser());

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/', (req, res) => {
  return res.status(200).json({ status: 'ok' });
});

app.use('/api/v1/leto', letoRoute);

app.use(globalErrorHanlder);

export default app;
