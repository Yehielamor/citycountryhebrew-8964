CREATE TABLE users (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email text,
    username text UNIQUE NOT NULL,
    avatar_url text,
    total_score integer DEFAULT 0,
    games_played integer DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE games (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    letter text NOT NULL,
    categories jsonb NOT NULL,
    status text NOT NULL DEFAULT 'waiting',
    round_time integer DEFAULT 60,
    current_round integer DEFAULT 1,
    max_players integer DEFAULT 4,
    created_by uuid REFERENCES users(id) ON DELETE SET NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE game_players (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id uuid REFERENCES games(id) ON DELETE CASCADE,
    user_id uuid REFERENCES users(id) ON DELETE CASCADE,
    score integer DEFAULT 0,
    answers jsonb DEFAULT '{}',
    is_ready boolean DEFAULT false,
    joined_at timestamptz DEFAULT now(),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(game_id, user_id)
);

CREATE TABLE game_rounds (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id uuid REFERENCES games(id) ON DELETE CASCADE,
    round_number integer NOT NULL,
    letter text NOT NULL,
    start_time timestamptz DEFAULT now(),
    end_time timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(game_id, round_number)
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_rounds ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all users"
    ON users FOR SELECT
    USING (true);

CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can view all games"
    ON games FOR SELECT
    USING (true);

CREATE POLICY "Users can create games"
    ON games FOR INSERT
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Game creators can update their games"
    ON games FOR UPDATE
    USING (auth.uid() = created_by);

CREATE POLICY "Players can view game players"
    ON game_players FOR SELECT
    USING (true);

CREATE POLICY "Users can join games as players"
    ON game_players FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Players can update their own game data"
    ON game_players FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Players can view game rounds"
    ON game_rounds FOR SELECT
    USING (true);

CREATE POLICY "Game creators can insert rounds"
    ON game_rounds FOR INSERT
    WITH CHECK (EXISTS (SELECT 1 FROM games WHERE games.id = game_rounds.game_id AND games.created_by = auth.uid()));

CREATE POLICY "Game creators can update rounds"
    ON game_rounds FOR UPDATE
    USING (EXISTS (SELECT 1 FROM games WHERE games.id = game_rounds.game_id AND games.created_by = auth.uid()));

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_games_created_by ON games(created_by);
CREATE INDEX idx_games_status ON games(status);
CREATE INDEX idx_game_players_game_id ON game_players(game_id);
CREATE INDEX idx_game_players_user_id ON game_players(user_id);
CREATE INDEX idx_game_rounds_game_id ON game_rounds(game_id);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_games_updated_at BEFORE UPDATE ON games FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_game_players_updated_at BEFORE UPDATE ON game_players FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_game_rounds_updated_at BEFORE UPDATE ON game_rounds FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();