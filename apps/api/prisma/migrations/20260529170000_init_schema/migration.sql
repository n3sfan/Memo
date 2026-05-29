CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider text NOT NULL CHECK (provider IN ('apple', 'google')),
  provider_user_id text NOT NULL,
  email text,
  display_name text,
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT users_provider_provider_user_id_key UNIQUE (provider, provider_user_id)
);

CREATE TABLE maps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL CHECK (type IN ('personal', 'duo')),
  owner_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE map_members (
  map_id uuid NOT NULL REFERENCES maps(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('owner', 'member')),
  joined_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (map_id, user_id)
);

CREATE TABLE pins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  map_id uuid NOT NULL REFERENCES maps(id) ON DELETE CASCADE,
  created_by uuid NOT NULL REFERENCES users(id),
  title text,
  note text,
  memory_date timestamptz,
  lat double precision NOT NULL CHECK (lat BETWEEN -90 AND 90),
  lng double precision NOT NULL CHECK (lng BETWEEN -180 AND 180),
  geom geometry(Point, 4326) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_pins_geom ON pins USING GIST (geom);
CREATE INDEX idx_pins_map_memory ON pins (map_id, memory_date DESC);

CREATE TABLE media_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pin_id uuid NOT NULL REFERENCES pins(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('image', 'audio', 'text')),
  object_key text NOT NULL,
  mime text,
  size_bytes bigint CHECK (size_bytes IS NULL OR size_bytes >= 0),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'ready')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE invitations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  map_id uuid NOT NULL REFERENCES maps(id) ON DELETE CASCADE,
  created_by uuid NOT NULL REFERENCES users(id),
  code text NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'revoked', 'expired')),
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT invitations_code_key UNIQUE (code)
);

CREATE UNIQUE INDEX uniq_pending_invitation
  ON invitations (map_id)
  WHERE status = 'pending';

CREATE TABLE share_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pin_id uuid NOT NULL REFERENCES pins(id) ON DELETE CASCADE,
  created_by uuid NOT NULL REFERENCES users(id),
  token text NOT NULL,
  revoked boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT share_links_token_key UNIQUE (token)
);
