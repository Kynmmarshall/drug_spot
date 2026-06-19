# Drug Spot

A Flutter mobile application that helps patients locate pharmacies and find available medicines nearby, with pricing and distance information..

## Features

- **Dual dashboards** - Separate interfaces for patients and pharmacy owners
- **Medicine search** - Real-time search with distance and price filters
- **Community map** - Visual map of all pharmacy locations with distance calculations
- **Pharmacy management** - Add, edit, and delete medicines (pharmacy owners)
- **Medicine requests** - Patients can request medicines; pharmacies can view requests
- **Profile management** - Editable profile with avatar selection
- **Bilingual** - Full English and French language support
- **Dark / Light theme** - Toggle between themes across the app

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── app_state.dart            # Global state (ChangeNotifier)
│   ├── app_theme.dart            # Material 3 light/dark themes
│   ├── localizer.dart            # EN/FR translation strings
│   └── context_extensions.dart   # BuildContext helpers
├── models/
│   ├── medicine.dart
│   ├── medicine_request.dart
│   ├── pharmacy.dart
│   ├── user_profile.dart
│   ├── geo_point.dart
│   ├── user_type.dart            # patient / pharmacy enum
│   └── app_language.dart         # en / fr enum
├── screens/
│   ├── login_screen.dart
│   ├── registration_screen.dart
│   ├── patient_dashboard_screen.dart
│   ├── pharmacy_dashboard_screen.dart
│   ├── medicine_detail_screen.dart
│   ├── my_medicines_screen.dart
│   ├── pharmacy_requests_screen.dart
│   ├── community_map_screen.dart
│   └── profile_screen.dart
├── services/
│   └── location_service.dart     # Geolocation detection
└── widgets/
    ├── dashboard_action_bar.dart
    ├── language_toggle.dart
    ├── medicine_form_sheet.dart
    ├── medicine_tile.dart
    ├── pharmacy_map_card.dart
    ├── profile_avatar.dart
    ├── section_card.dart
    └── theme_toggle_button.dart
```

## Tech Stack

- **Flutter** 3.9+ / Dart
- **State management** - `ChangeNotifier` + `Provider`
- **Theming** - Material 3 with Google Fonts (Space Grotesk)
- **SVG rendering** - `flutter_svg`
- **Localization** - Custom `Localizer` with `intl`

## Getting Started

```bash
# Clone the repo
git clone <repo-url>
cd drug_spot

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

## Backend

The REST API is built with Django REST Framework and lives in the [drug_spot_backend](../drug_spot_backend) repo. See its README for setup instructions.

| Endpoint                       | Method | Description              |
|--------------------------------|--------|--------------------------|
| `/api/register`                | POST   | Register a new user      |
| `/api/login`                   | POST   | Login, returns JWT token |
| `/api/profile`                 | GET/PUT| User profile             |
| `/api/pharmacies/`             | GET    | List all pharmacies      |
| `/api/medicines/`              | GET/POST| List or add medicines   |
| `/api/medicines/<id>`          | GET/PUT/DELETE | Medicine CRUD     |
| `/api/medicines/pharmacy/<id>` | GET    | Medicines by pharmacy    |
| `/api/medicine_requests/`      | GET/POST| Medicine requests       |

## Roadmap

- [ ] Connect frontend to Django REST backend
- [ ] Real GPS geolocation (replace mock location service)
- [ ] Google Maps integration (replace custom painted map)
- [ ] Map directions to pharmacy
- [ ] Medicine availability indicator
- [ ] Chat between patient and pharmacy
- [ ] Push notifications
- [ ] Medicine image uploads
- [ ] Pharmacy subscription / payment gate
