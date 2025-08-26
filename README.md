# RFID Parent Notification System

A complete system that notifies parents when their child's RFID card is tapped.

## System Components

1. **ESP32 Firmware** - Reads RFID cards and sends data to the backend
2. **Backend API** (Vercel) - Receives tap data, stores in Supabase, sends notifications
3. **Mobile App** (Flutter) - Allows parents to register cards and receive notifications
4. **Database** (Supabase) - Stores users, cards, and tap events
5. **Notifications** (Firebase FCM) - Sends push notifications to parents

## Setup Guide

See [docs/SETUP.md](docs/SETUP.md) for detailed setup instructions.