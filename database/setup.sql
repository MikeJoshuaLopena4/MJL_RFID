-- Users table
CREATE TABLE users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  fcm_token TEXT
);

-- RFID cards table
CREATE TABLE rfid_cards (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  uid TEXT UNIQUE NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tap events table
CREATE TABLE tap_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  card_uid TEXT NOT NULL,
  tapped_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  mac_address TEXT NOT NULL
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE rfid_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE tap_events ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own cards" ON rfid_cards FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own cards" ON rfid_cards FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own cards" ON rfid_cards FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Anyone can insert tap events" ON tap_events FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can view tap events for their cards" ON tap_events FOR SELECT USING (
  card_uid IN (SELECT uid FROM rfid_cards WHERE user_id = auth.uid())
);