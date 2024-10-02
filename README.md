# gh247_user

Giao hang 247 user mobile application.

## Used Techniques

- Flutter (3.22.2) + Riverpod + Dio

## Project structure

lib/
├── core/
│ ├── constants/ # Contains global constants (API URLs, keys...)
│ ├── utils/ # Ultilities
│ ├── theme/ # Define theme (text, appbar...)
│ ├── errors/ # Define exceptions and errors handlers
│ ├── services/ # Global services such as cache management or notification service
│ └── widgets/ # Common widgets can be reused in application
│
├── features/
│ ├── authentication/ # Name of feature, here is authentication
│ │ ├── controller/ # Contains controllers to manage state and user interaction
│ │ ├── data/ # Contains logic to manage data (repository, dto, data source)
│ │ ├── models/ # Models
│ │ └── views/ # User interface
│ ├── home/ # Home feature
│
├── app.dart # Setup application before running
├── main.dart # Run application
└── README.md

## Generate code with freezed, auto_route_generator

`[fvm] dart pub run build_runner build --delete-conflicting-outputs`

## Generate translated messages code

`[fvm] flutter pub run intl_utils:generate`

## Generate assets class

`fluttergen -c pubspec.yaml`

## Common rules folow dart standard

    1. Naming convention:
        - Name file using snake style
        - Name class/ variable/ function using camel style
        - Each screen is one folder with controllers, models, views and data
        - Main screen end with _page.dart
    2. Common styles:
        - Declare common constants color/ textstyle/ dimension... in app_styles.dart
        - Decalre in views/components if these styles used multiple screen in a features
        - Declare as constant in ahead of class if multiple use in one screen
        - Hard code if these styles just used only one screen

## Generate splash screen

- [flutter_native_splash](https://pub.dev/packages/flutter_native_splash)
- `[fvm] flutter pub run flutter_native_splash:create`

## Test and get coverage

`sh coverage.sh`
