import dotenv from 'dotenv';
dotenv.config();

import app from './app';

const port = process.env.PORT || 7000;

const main = async () => {
  const server = app.listen(port, () => {
    console.log(`[server]: Server is running on port: ${port}`);
  });

  process.on('unhandledRejection', (err: Error) => {
    console.log('____ 🔥 Unhandled rejection ____');
    console.log(err.message);
    server.close(() => {
      process.exit(1);
    });
  });
};

main();
