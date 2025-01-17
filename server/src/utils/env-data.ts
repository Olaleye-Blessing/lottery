import { z } from 'zod';

const envSchema = z.object({
  PORT: z.coerce.number().min(3000),
  ALLOWED_ORIGINS: z.string(),
  NODE_ENV: z
    .union([
      z.literal('development'),
      z.literal('test'),
      z.literal('production'),
    ])
    .default('development'),
});

export type Environment = z.infer<typeof envSchema>;

const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.log('There is an error with the server environment variables');
  console.error(parsedEnv.error.issues);
  process.exit(1);
}

export const envVars = parsedEnv.data;
