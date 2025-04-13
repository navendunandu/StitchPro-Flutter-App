# StitchPro - Tailoring Management System

StitchPro is a comprehensive tailoring management system consisting of three interconnected applications:
- User App (Customer Interface)
- Tailor App (Tailor Interface)
- Admin Dashboard (Management Interface)

## User App

The User App is designed for customers to easily connect with tailors and manage their tailoring orders.

### Features

#### 1. Authentication
- User registration and login
- Profile management
- Secure authentication using Supabase

#### 2. Tailor Discovery
- Search and browse tailors
- View tailor profiles and ratings
- Filter by location and specialization

#### 3. Booking Management
- Schedule appointments
- Track order status
- View booking history
- Real-time updates

#### 4. Payment Integration
- Secure payment processing using Razorpay
- Multiple payment options
- Transaction history

#### 5. Communication
- Direct messaging with tailors
- Order specifications sharing
- Complaint management system

### Technical Stack

- **Framework**: Flutter
- **Backend**: Supabase
- **State Management**: Native Flutter State
- **Payment Gateway**: Razorpay
- **Database**: PostgreSQL (via Supabase)
- **Storage**: Supabase Storage

### Dependencies

```yaml
dependencies:
  file_picker: ^9.2.1
  flutter: sdk: flutter
  fluttertoast: ^8.2.12
  google_fonts: ^6.2.1
  image_picker: ^1.1.2
  intl: ^0.20.2
  razorpay_flutter: ^1.4.0
  supabase_flutter: ^2.8.4
```

### Getting Started

1. **Setup Flutter Environment**
   ```bash
   flutter pub get
   ```

2. **Configure Supabase**
   - Create a Supabase project
   - Update the Supabase credentials in `lib/main.dart`

3. **Configure Razorpay**
   - Set up a Razorpay account
   - Add API keys to the payment configuration

4. **Run the App**
   ```bash
   flutter run
   ```

### Project Structure

```
userapp/
├── lib/
│   ├── main.dart
│   ├── home.dart
│   ├── login.dart
│   ├── screens/
│   │   ├── booking/
│   │   ├── profile/
│   │   ├── search/
│   │   └── payment/
│   ├── widgets/
│   └── utils/
├── assets/
└── test/
```

### Environment Requirements

- Flutter SDK: ^3.6.1
- Dart: ^3.0.0
- Android Studio / VS Code
- Android SDK / Xcode (for iOS)

### Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

### Related Projects

- [Tailor App](../tailor_app)
- [Admin Dashboard](../Admin)

### License

This project is licensed under the MIT License - see the LICENSE file for details.

### Support

For support, please contact:
- Email: support@stitchpro.com
- Website: www.stitchpro.com

### Acknowledgments

- Flutter Team
- Supabase
- Razorpay
- All contributors

---

© 2024 StitchPro. All rights reserved.
