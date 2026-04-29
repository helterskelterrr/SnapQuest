-- SnapQuest Supabase Schema
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/ghjchrjykfnzpsdcuujt/sql

-- ── Users ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            VARCHAR(128) PRIMARY KEY,  -- Firebase UID
  username      TEXT         NOT NULL,
  username_lower TEXT        NOT NULL,
  email         TEXT         NOT NULL,
  bio           TEXT         NOT NULL DEFAULT '',
  photo_url     TEXT         NOT NULL DEFAULT '',
  total_xp      INTEGER      NOT NULL DEFAULT 0,
  weekly_points INTEGER      NOT NULL DEFAULT 0,
  rank          TEXT         NOT NULL DEFAULT 'Rookie Snapper',
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS users_username_lower_idx ON users (username_lower);

-- ── Challenges ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS challenges (
  id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  title         TEXT         NOT NULL,
  description   TEXT         NOT NULL DEFAULT '',
  date          DATE         NOT NULL,
  created_by    VARCHAR(128) REFERENCES users(id) ON DELETE SET NULL,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS challenges_date_idx ON challenges (date);

-- ── Submissions ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS submissions (
  id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       VARCHAR(128) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  challenge_id  UUID         NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  photo_url     TEXT         NOT NULL,
  caption       TEXT         NOT NULL DEFAULT '',
  vote_count    INTEGER      NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS submissions_user_idx       ON submissions (user_id);
CREATE INDEX IF NOT EXISTS submissions_challenge_idx  ON submissions (challenge_id);
CREATE INDEX IF NOT EXISTS submissions_created_idx    ON submissions (created_at DESC);

-- ── Votes ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS votes (
  id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  voter_id      VARCHAR(128) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  submission_id UUID         NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  CONSTRAINT votes_unique UNIQUE (voter_id, submission_id)
);

CREATE INDEX IF NOT EXISTS votes_submission_idx ON votes (submission_id);
CREATE INDEX IF NOT EXISTS votes_voter_idx      ON votes (voter_id);

-- ── Comments ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS comments (
  id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       VARCHAR(128) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  submission_id UUID         NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
  content       TEXT         NOT NULL,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS comments_submission_idx ON comments (submission_id);
CREATE INDEX IF NOT EXISTS comments_user_idx       ON comments (user_id);

-- ── Reports ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reports (
  id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id   VARCHAR(128) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  submission_id UUID         NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
  reason        TEXT         NOT NULL,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS reports_submission_idx ON reports (submission_id);

-- ── Notifications ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id  VARCHAR(128) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sender_id     VARCHAR(128)             REFERENCES users(id) ON DELETE SET NULL,
  type          TEXT         NOT NULL,
  message       TEXT         NOT NULL,
  submission_id UUID                     REFERENCES submissions(id) ON DELETE CASCADE,
  is_read       BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS notifications_recipient_idx ON notifications (recipient_id, created_at DESC);

-- ── Row Level Security ────────────────────────────────────────────────────────
-- Disable RLS for all tables (Firebase handles auth, we trust Firebase UID)
ALTER TABLE users         DISABLE ROW LEVEL SECURITY;
ALTER TABLE challenges    DISABLE ROW LEVEL SECURITY;
ALTER TABLE submissions   DISABLE ROW LEVEL SECURITY;
ALTER TABLE votes         DISABLE ROW LEVEL SECURITY;
ALTER TABLE comments      DISABLE ROW LEVEL SECURITY;
ALTER TABLE reports       DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
