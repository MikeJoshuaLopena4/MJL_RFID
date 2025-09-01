# RFID Attendance System  

A full-stack **RFID Attendance and Notification System** built with:  
- **Next.js (TypeScript)** – Backend API + Web Dashboard  
- **Flutter** – Mobile app for users/parents to log in and receive notifications  
- **ESP32/ESP8266 Firmware** – Embedded system that scans RFID cards, sends logs via HTTP POST, and supports OTA updates  

---

## 📂 Project Structure  

```
.
├── my-app/                 # Server (Next.js + TypeScript + Firebase)
│   ├── app/                # Next.js routes and dashboard
│   ├── lib/                # Firebase client/server config
│   └── ...                 
│
├── my-flutter/
│   └── my_rfid/            # Flutter mobile app
│
├── firmware/               # Embedded system firmware
│   ├── src/                # Main Arduino/PlatformIO source
│   └── ota/                # OTA update code
│
└── README.md
```

## 🚀 Features  

- **RFID Logs** – Captured by ESP and stored in Firestore via server API  
- **Sessions** – Daily AM/PM In/Out tracking  
- **User Management** – Link RFID cards to registered users  
- **Web Dashboard** (Next.js)  
  - View logs and sessions in real time  
  - Highlight unregistered cards  
- **Mobile App** (Flutter)  
  - Login/Signup with Firebase Auth  
  - Parents/students can view activity  
  - Push notifications via FCM  
- **Firmware** (ESP32/8266)  
  - Reads RFID tags  
  - Sends POST request to server  
  - Supports OTA firmware updates  



## ⚙️ Setup Instructions  

### 1. Backend (Next.js + Firebase)  

1. Go to `my-app/`  
2. Install dependencies:  
   ```bash
   cd my-app
   npm install
Create a .env.local file with your Firebase config:

env
```
NEXT_PUBLIC_FIREBASE_API_KEY=xxxx
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=xxxx
NEXT_PUBLIC_FIREBASE_PROJECT_ID=xxxx
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=xxxx
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=xxxx
NEXT_PUBLIC_FIREBASE_APP_ID=xxxx
```
Run dev server:

npm run dev
2. Mobile App (Flutter)
Go to my-flutter/my_rfid/

Install dependencies:

:- cd my-flutter/my_rfid
:- flutter pub get

Run on emulator or device:
:- flutter run

3. Firmware (ESP32/ESP8266)
Go to firmware/
Open in Arduino IDE or PlatformIO
Configure WiFi SSID, Password, and Server URL in config.h (or main sketch)

Flash the board:
pio run --target upload
OTA Update: Once device is running, you can push new firmware via WiFi

🔐 Firestore Rules (Sample)
js

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Logs
    match /rfidLogs/{docId} {
      allow read: if true;
      allow write: if true; // ESP posts logs
    }

    // Sessions
    match /rfidSessions/{dayId} {
      allow read: if true;
      allow write: if true;
      match /cards/{cardId} {
        allow read, write: if true;
      }
    }

    // Users
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /ids/{id} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Default deny
    match /{document=**} {
      allow read, write: if false;
    }
  }
}

📸 Screenshots
Dashboard – real-time logs & sessions
Mobile app – notifications & attendance records
ESP firmware – RFID scanning and POST request

📌 Roadmap
 Add admin panel for managing users/cards
 Export reports (CSV/PDF)
 Improve OTA update UI
 Role-based Firestore rules

🛠️ Tech Stack
Frontend: Flutter, TailwindCSS (dashboard UI)
Backend: Next.js (TypeScript), Firebase Firestore, Firebase Auth
Embedded: ESP32/ESP8266, MFRC522 (RFID reader), Arduino/PlatformIO
Notifications: Firebase Cloud Messaging (FCM)


🙌 Acknowledgements
Firebase
Flutter
Next.js
PlatformIO
