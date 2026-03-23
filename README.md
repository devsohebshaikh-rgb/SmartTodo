# Smart Location Todo

A location-based task reminder mobile application. Users create tasks associated with specific locations and dates. When the user enters the location area, the app automatically alerts with alarm, notification, and vibration.

## Tech Stack

- **Mobile**: Flutter (Dart)
- **Backend**: Node.js + Express.js
- **Database**: MySQL (raw SQL queries, no ORM)
- **Auth**: JWT + bcrypt

## Prerequisites

- Node.js 18+
- MySQL 8.0+
- Flutter SDK 3.2+
- Android Studio / Xcode
- Google Maps API Key

## Project Structure

```
SmartTodo/
├── backend/
│   ├── config/          # Database configuration
│   ├── controllers/     # Request handlers
│   ├── db/              # SQL schema, seeds, setup scripts
│   ├── middleware/       # JWT auth middleware
│   ├── routes/          # API route definitions
│   ├── services/        # Business logic & DB queries
│   └── server.js        # Entry point
├── mobile_app/
│   └── lib/
│       ├── models/      # Data models
│       ├── providers/   # State management (Provider)
│       ├── screens/     # UI screens
│       ├── services/    # API, geofence, notification services
│       ├── utils/       # Constants, helpers
│       ├── widgets/     # Reusable widgets
│       └── main.dart    # Entry point
└── README.md
```

## Backend Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your MySQL credentials:

```
PORT=3000
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=smart_todo
JWT_SECRET=your_secret_key_here
JWT_EXPIRES_IN=7d
```

### 3. Setup Database

Create the database and tables:

```bash
# Option A: Run setup script
npm run db:setup

# Option B: Manual SQL
mysql -u root -p < db/database.sql
```

### 4. Seed Demo Data

```bash
npm run db:seed
```

This creates:
- **Demo user**: `demo@demo.com` / `123456`
- Sample tasks in Pune, Mumbai, and Delhi

### 5. Start Server

```bash
# Development (with auto-reload)
npm run dev

# Production
npm start
```

Server runs at `http://localhost:3000`

### 6. Verify

```bash
curl http://localhost:3000/api/health
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login |
| POST | `/api/location` | Create location |
| GET | `/api/location/user/:id` | Get user locations |
| POST | `/api/todo` | Create todo |
| GET | `/api/todos/user/:id` | Get user todos |
| GET | `/api/todos/today` | Get today's todos |
| GET | `/api/todos/upcoming` | Get upcoming todos |
| PUT | `/api/todo/:id` | Update todo |
| DELETE | `/api/todo/:id` | Delete todo |
| POST | `/api/notification/trigger` | Trigger notification |

All endpoints except auth require `Authorization: Bearer <token>` header.

## Flutter App Setup

### 1. Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Enable **Maps SDK for Android** and **Maps SDK for iOS**
3. Create an API key

**Android**: Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

**iOS**: Add to `ios/Runner/AppDelegate.swift`:
```swift
GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

### 2. Configure API URL

Edit `lib/utils/constants.dart`:
- Android emulator: `http://10.0.2.2:3000/api`
- iOS simulator: `http://localhost:3000/api`
- Physical device: `http://YOUR_LOCAL_IP:3000/api`

### 3. Android Permissions

The following permissions are configured in `AndroidManifest.xml.example`. Ensure they are in your actual manifest:
- `ACCESS_FINE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `POST_NOTIFICATIONS`
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_LOCATION`

### 4. Install & Run

```bash
cd mobile_app
flutter pub get
flutter run
```

### 5. iOS Additional Setup

```bash
cd ios
pod install
cd ..
flutter run
```

## Demo Walkthrough

1. **Start backend**: `cd backend && npm run dev`
2. **Run Flutter app**: `cd mobile_app && flutter run`
3. **Login**: `demo@demo.com` / `123456`
4. **Home Dashboard**: View today's and upcoming tasks
5. **Enable Tracking**: Toggle location tracking ON in the app bar
6. **Add Task**: Tap "+", pick location on map, select date, add tasks
7. **Map View**: See all tasks as colored markers on the map
8. **Geofence Alert**: When you enter a task location area (700m radius), receive notification + alarm

## Features

- **User Authentication** — Register, login, logout with JWT
- **Home Dashboard** — Today's tasks, upcoming tasks, quick add
- **Location Picker** — Google Maps integration for selecting task locations
- **Background Geofencing** — Alerts even when app is minimized/closed
- **Map Visualization** — Color-coded markers (red=pending, green=completed, blue=upcoming)
- **Smart Reminders** — Alarm + notification + vibration when entering geofence on task date
- **Task Management** — Create, edit, complete, delete tasks
- **Task History** — View completed, missed, and upcoming tasks

## Geofencing Logic

Uses the **Haversine formula** to calculate distance between user position and task locations:

```
a = sin²(Δlat/2) + cos(lat1) × cos(lat2) × sin²(Δlon/2)
c = 2 × atan2(√a, √(1−a))
d = R × c
```

Default reminder radius: **700 meters**

When `distance < reminder_radius` AND `task_date == today` → trigger reminder.

## Security

- Passwords hashed with bcrypt (10 rounds)
- JWT token authentication
- Protected API routes via auth middleware
- Prepared SQL statements (SQL injection prevention)
- Input validation on all endpoints
