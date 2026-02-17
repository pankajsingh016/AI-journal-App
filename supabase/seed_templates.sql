-- Optional: seed system templates. Run in Supabase SQL Editor after schema.sql.
-- Uses auth.uid() = NULL for system templates so created_by is NULL and is_system = TRUE.

INSERT INTO templates (name, description, category, structure, is_system, created_by)
VALUES
  ('Gratitude', 'List three things you are grateful for today.', 'gratitude', '{"title": "Gratitude", "content": "1. \n2. \n3. "}'::jsonb, TRUE, NULL),
  ('Daily reflection', 'Reflect on your day in a few sentences.', 'reflection', '{"title": "Daily reflection", "content": "Today I felt...\n\nSomething that went well:\n\nSomething I could improve:\n"}'::jsonb, TRUE, NULL),
  ('Morning pages', 'Classic morning pages: write freely for a few minutes.', 'freewriting', '{"title": "Morning pages", "content": "..."}'::jsonb, TRUE, NULL),
  ('Highs and lows', 'One high and one low from today.', 'reflection', '{"title": "Highs and lows", "content": "High: \n\nLow: \n"}'::jsonb, TRUE, NULL),
  ('Intentions', 'Set intentions for tomorrow.', 'planning', '{"title": "Intentions for tomorrow", "content": "I will...\n\nI want to...\n"}'::jsonb, TRUE, NULL);
