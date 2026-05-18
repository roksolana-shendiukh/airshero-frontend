# AirShero — Frontend

Web application for airline operations management built with Flutter. 
The system supports three roles: Sales Agent, Check-in Agent, and Flight Planning Manager, 
as well as an Admin panel for user and system management.

## Tech Stack

- **Flutter** / **Dart** — UI framework
- **Provider** — state management
- **GoRouter** — navigation
- **Dio** / **HTTP** — REST API communication
- **GraphQL Flutter** — GraphQL queries
- **FL Chart** — analytics charts
- **Flutter Map** — interactive maps
- **Google Fonts** / **Font Awesome** — UI & icons


## Features

- 🔐 Authentication via Firebase
- 🎫 Flight search, booking and payment
- 🧳 Baggage selection and management
- 👤 Passenger check-in with seat map
- 🛫 Flight operations management
- 📅 Flight planning and scheduling
- 💰 Dynamic pricing management
- 📊 Admin analytics and audit log
- 👥 User management (Admin panel)


## Architecture

The project follows a layered architecture:

- **pages/** — UI screens grouped by role: admin, sales, checkin, planning, operations
- **services/** — API communication layer, one service per domain
- **models/** — data transfer objects
- **widgets/** — reusable UI components grouped by feature
- **config/** — routing and theming


## Getting Started

### Prerequisites
- Flutter SDK ^3.9.2
- Dart SDK
- Running [AirShero Backend](https://github.com/roksolana-shendiukh/CW_B)

### Installation

1. Clone the repository
```bash
   git clone https://github.com/roksolana-shendiukh/CW_F.git
   cd CW_F
```

2. Install dependencies
```bash
   flutter pub get
```

3. Run the app
```bash
   flutter run -d chrome
```

## Screenshots

### Booking — Flight Search
![Flight Search](https://github.com/user-attachments/assets/f768ec69-48c5-48ab-9342-418234eb43bf)

### Booking — Flight Cards
![Flight Cards](https://github.com/user-attachments/assets/f7b6ba4c-b2d7-47f3-bf98-c7d59e766177>)

### Check-in — Seat Map
![Seat Map](image" src="https://github.com/user-attachments/assets/4675d878-3e09-4781-a183-db12ebe51bd9>).

### Check-in — Boarding Pass
![Boarding Pass](https://github.com/user-attachments/assets/9af275c4-3400-4587-8597-446415ac2607>)

### Flight Operations — Create Operation
![Create Operation](https://github.com/user-attachments/assets/3b797207-ada0-4aa0-a472-ea7f83624da3>)

### Flight Operations — Operation Details
![Operation Details](https://github.com/user-attachments/assets/139c063c-fba0-438e-8fad-a22ab255ad94>)

### Planning — Flights List
![Flights List](https://github.com/user-attachments/assets/6b62e101-0a13-4e5a-8c8e-6c0337b0affb>)

