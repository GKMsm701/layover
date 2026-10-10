CREATE TABLE IF NOT EXISTS sq_profiles (
  id TEXT PRIMARY KEY,
  nickname TEXT NOT NULL CHECK (char_length(nickname) BETWEEN 1 AND 24),
  preferred_language TEXT NOT NULL DEFAULT 'English',
  connection_preferences TEXT NOT NULL DEFAULT 'both' CHECK (connection_preferences IN ('friendship','romance','both')),
  interests JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS sq_quest_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  city TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting','active','completed','cancelled')),
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS sq_quest_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quest_session_id UUID NOT NULL REFERENCES sq_quest_sessions(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL,
  secret_codename TEXT NOT NULL,
  participant_status TEXT NOT NULL DEFAULT 'active' CHECK (participant_status IN ('active','left','completed')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (quest_session_id, user_id)
);
CREATE TABLE IF NOT EXISTS sq_missions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  mission_type TEXT NOT NULL DEFAULT 'photo',
  duration_seconds INTEGER NOT NULL DEFAULT 600 CHECK (duration_seconds > 0),
  required_letters INTEGER NOT NULL DEFAULT 1 CHECK (required_letters BETWEEN 1 AND 6),
  active BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE IF NOT EXISTS sq_mission_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mission_id UUID NOT NULL REFERENCES sq_missions(id) ON DELETE CASCADE,
  location_name TEXT NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  verification_radius INTEGER NOT NULL DEFAULT 100 CHECK (verification_radius BETWEEN 10 AND 1000),
  accessibility_notes TEXT,
  active BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE TABLE IF NOT EXISTS sq_mission_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quest_participant_id UUID NOT NULL REFERENCES sq_quest_participants(id) ON DELETE CASCADE,
  mission_id UUID NOT NULL REFERENCES sq_missions(id) ON DELETE CASCADE,
  photo_path TEXT,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending','approved','rejected')),
  verification_notes TEXT,
  UNIQUE (quest_participant_id, mission_id)
);
CREATE TABLE IF NOT EXISTS sq_participant_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quest_participant_id UUID NOT NULL REFERENCES sq_quest_participants(id) ON DELETE CASCADE,
  mission_id UUID NOT NULL REFERENCES sq_missions(id) ON DELETE CASCADE,
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  unlocked_letters TEXT NOT NULL DEFAULT '',
  UNIQUE (quest_participant_id, mission_id)
);
CREATE TABLE IF NOT EXISTS sq_meetup_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quest_session_id UUID NOT NULL REFERENCES sq_quest_sessions(id) ON DELETE CASCADE,
  inviter_user_id TEXT NOT NULL,
  invitee_user_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','confirmed','declined','cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded_at TIMESTAMPTZ,
  CHECK (inviter_user_id <> invitee_user_id)
);
CREATE TABLE IF NOT EXISTS sq_safety_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_user_id TEXT NOT NULL,
  reported_user_id TEXT NOT NULL,
  quest_session_id UUID REFERENCES sq_quest_sessions(id) ON DELETE SET NULL,
  category TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','reviewing','resolved','dismissed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS sq_sessions_city_status_idx ON sq_quest_sessions(city, status);
CREATE INDEX IF NOT EXISTS sq_participants_user_status_idx ON sq_quest_participants(user_id, participant_status);
CREATE INDEX IF NOT EXISTS sq_submissions_status_idx ON sq_mission_submissions(verification_status);
CREATE INDEX IF NOT EXISTS sq_meetups_session_status_idx ON sq_meetup_invitations(quest_session_id, status);