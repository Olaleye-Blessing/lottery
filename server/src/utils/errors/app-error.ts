export class AppError extends Error {
  readonly status: string;
  readonly isOperational: boolean;

  constructor(
    message: string,
    public statusCode = 400,
  ) {
    super(message);
    this.status = String(statusCode).startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;
    Error.captureStackTrace(this);
  }
}
