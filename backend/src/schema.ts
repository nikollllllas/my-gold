import { pgTable, serial, text, boolean, numeric, timestamp, integer } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  email: text('email').notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  isPremium: boolean('is_premium').notNull().default(false),
  stripeCustomerId: text('stripe_customer_id'),
  fcmToken: text('fcm_token'),
  createdAt: timestamp('created_at').notNull().defaultNow(),
});

export const alerts = pgTable('alerts', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').notNull().references(() => users.id),
  targetPrice: numeric('target_price', { precision: 12, scale: 2 }).notNull(),
  direction: text('direction', { enum: ['above', 'below'] }).notNull(),
  triggered: boolean('triggered').notNull().default(false),
  createdAt: timestamp('created_at').notNull().defaultNow(),
});

export const subscriptions = pgTable('subscriptions', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').notNull().references(() => users.id),
  stripeSubscriptionId: text('stripe_subscription_id').notNull().unique(),
  status: text('status').notNull(),
  currentPeriodEnd: timestamp('current_period_end'),
});
