# pdf_signature

A GUI app to create signatures on PDF pages interactively.

## Features

checkout [`docs/FRs.md`](docs/FRs.md)

## run

```bash
# flutter clean
# arb_translate
flutter pub get
# > to generate gherkin test
flutter pub run build_runner build --delete-conflicting-outputs
# > to remove unused step definitions
# dart run tool/prune_unused_steps.dart --delete
# > to static analyze the code
flutter analyze
# > run unit tests and widget tests
flutter test
# > run integration tests
flutter test integration_test/ -d <device_id>

# dart run tool/gen_view_wireframe_md.dart
# flutter pub run dead_code_analyzer

# run the app
flutter run -d <device_id>
```

### build

#### Windows

```bash
flutter build windows
# create windows installer
flutter pub run msix:create
```

#### web

```bash
flutter build web
# flutter build web --release -O4 --wasm
```
Open the `index.html` file in the `build/web` directory. Remove the `<base href="/">` to ensure proper routing on GitHub Pages.

##### Docker

To build and run a minimal Docker image serving static Flutter web files:

```bash
# Build the Docker image
docker build -t pdf_signature .

# Run the container (serves static files on port 8080)
docker run --rm -p 8080:8080 pdf_signature

# act push -P ubuntu-latest=catthehacker/ubuntu:act-latest --container-options "--privileged" --env-file .env --secret-file .secrets
```
Access your app at [http://localhost:8080](http://localhost:8080)

#### Linux

For Linux

```bash
flutter build linux
cp -r build/linux/x64/release/bundle/ AppDir
appimagetool-x86_64.AppImage AppDir
```
