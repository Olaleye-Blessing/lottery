/* eslint-disable @typescript-eslint/no-explicit-any */
import { Response } from "express";
export const sendResponse = (
  res: Response<any, Record<string, any>>,
  status: number,
  data: object,
) => {
  res.status(status).json({ status: "success", data });
};
