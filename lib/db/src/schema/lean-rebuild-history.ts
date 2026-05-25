import { pgTable, serial, text, integer, boolean, timestamp, index } from "drizzle-orm/pg-core";

export const leanRebuildHistoryTable = pgTable(
  "lean_rebuild_history",
  {
    id: serial("id").primaryKey(),
    timestamp: timestamp("timestamp", { withTimezone: true }).notNull().defaultNow(),
    durationMs: integer("duration_ms").notNull(),
    exitCode: integer("exit_code").notNull(),
    ok: boolean("ok").notNull(),
    error: text("error"),
    streamed: boolean("streamed").notNull(),
    refereeName: text("referee_name"),
  },
  (table) => ({
    timestampIdx: index("lean_rebuild_history_timestamp_idx").on(table.timestamp),
  }),
);

export type LeanRebuildHistoryRow = typeof leanRebuildHistoryTable.$inferSelect;
export type InsertLeanRebuildHistory = typeof leanRebuildHistoryTable.$inferInsert;
