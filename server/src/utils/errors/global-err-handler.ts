import { NextFunction, Request, Response } from "express";
import { AppError } from "./app-error";
import { envVars } from "../env-data";

export const globalErrorHanlder = async (
  err: Error | AppError,
  _req: Request,
  res: Response,
  // eslint-disable-next-line no-unused-vars, @typescript-eslint/no-unused-vars
  _next: NextFunction,
) => {
  let error: AppError;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  error = err as any;

  if (!(error instanceof AppError)) {
    error = new AppError('Something went wrong!! Try again later', 500);
  }

  const resBody: { [key: string]: string | Error } = {
    status: error!.status,
    message: error!.message,
  };

  if (envVars.NODE_ENV !== 'production') resBody.err = err;

  return res.status(error!.statusCode).json(resBody);
};
