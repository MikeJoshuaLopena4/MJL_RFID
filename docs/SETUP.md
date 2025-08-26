# Setup Guide

## 1. Supabase Database Setup

1. Create a Supabase account at https://supabase.com
2. Create a new project
3. Run the SQL queries from `/database/setup.sql`

## 2. Backend Setup (Vercel)

1. Fork this repository
2. Connect your GitHub account to Vercel
3. Deploy the backend from the `/backend` directory
4. Set up environment variables in Vercel:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_KEY`
   - `FIREBASE_SERVICE_ACCOUNT`

## 3. Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com/
2. Enable Cloud Messaging
3. Generate a service account key
4. Add the service account JSON to your Vercel environment variables

## 4. Flutter App Setup

1. Install Flutter SDK
2. Navigate to the `/mobile-app` directory
3. Run `flutter pub get`
4. Update Supabase and Firebase configuration
5. Run `flutter run`

## 5. ESP32 Firmware

1. Open `/firmware/rfid_reader.ino` in Arduino IDE
2. Install required libraries
3. Update the server URL to point to your Vercel deployment
4. Upload to your ESP32