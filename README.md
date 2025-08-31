# pdf_signature

A GUI app to create signatures on PDF pages interactively.

## Features

checkout [`docs/FRs.md`](docs/FRs.md)

## Build

```bash
# flutter clean
# arb_translate
flutter pub get
# generate gherkin test
flutter pub run build_runner build --delete-conflicting-outputs
# dart run tool/prune_unused_steps.dart --delete
# dart run tool/gen_view_wireframe_md.dart

# run the app
flutter run

# run unit tests and widget tests
flutter test

flutter build
# create windows installer
flutter pub run msix:create
```
