# layered_flutter_template

Reusable clean-architecture starter for Flutter projects and timed coding
assessments. **Infrastructure only — no feature code.** Every layer is empty and
waiting for you to fill it in.

---

## ⚠️ Do this first after cloning

Work through this list top to bottom. Items 1–3 are required for the app to be
yours; 4 only matters if you intend to ship.

### 1. Rename the package

`pubspec.yaml` and every Dart import still say `layered_flutter_template`.
Miss one and the analyzer throws `Target of URI doesn't exist`.

```bash
grep -rl layered_flutter_template lib test | xargs sed -i '' 's/layered_flutter_template/YOUR_APP_NAME/g'
```

Then rename the `name:` field in `pubspec.yaml` to match.

> This command is scoped to `lib/` and `test/` on purpose. It deliberately leaves
> this README alone so the instructions stay valid after you rename.

### 2. Delete the placeholder route

`lib/app/router.dart` ships with a temporary `/` route rendering a blank
`Scaffold` with the text `Template ready`. It exists only so the app boots with
zero real routes — `go_router` has nothing to match `/` against otherwise.

Delete that `GoRoute`, then drop `initialLocation` if you no longer need a
forced start location, and build your real route list in its place.

### 3. Fix the smoke test

`test/widget_test.dart` asserts `find.text('Template ready')`. It passes now
and **will fail the moment you complete step 2**. Replace it with a real test, or
delete it.

### 4. Change the bundle ID (only if shipping)

Scaffolded under `com.example`, so identifiers are placeholder values:

| Platform | File | Current value |
|---|---|---|
| Android | `android/app/build.gradle.kts` | `namespace` + `applicationId` = `com.example.layered_flutter_template` |
| iOS | `ios/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` = `com.example.layeredFlutterTemplate` |

Also update the user-visible app name in `android/app/src/main/AndroidManifest.xml`
(`android:label`) and `ios/Runner/Info.plist` (`CFBundleDisplayName`).

> This step is **not** a find-and-replace — the identifiers are spelled
> differently per platform. Easiest to catch it now than mid-deadline.

---

## Folder structure

```
lib/
├── app/                      # App shell, router config
│   ├── app.dart              # MaterialApp.router, M3, indigo seed
│   └── router.dart           # appRouter (GoRouter) — add routes here
├── core/
│   └── error/                # Shared, layer-agnostic primitives
│       ├── failure.dart      # Sealed Failure hierarchy
│       └── result.dart       # Sealed Result<T>, Ok/Err
├── data/                     # ── EMPTY: outer layer ──
│   ├── data_sources/         # remote/local data access (dio, storage)
│   ├── models/               # JSON DTOs
│   ├── mappers/              # model <-> entity conversion
│   └── repositories/         # Repository implementations
├── di/                       # ── EMPTY: Riverpod providers ──
├── domain/                   # ── EMPTY: pure Dart, no Flutter imports ──
│   ├── entities/             # business models
│   ├── repositories/         # abstract contracts (impl lives in data/)
│   └── usecases/             # one class per operation
├── presentation/
│   ├── screens/              # ── EMPTY: one widget per screen ──
│   └── widgets/              # Reusable UI pieces
│       ├── empty_view.dart   # no-content state
│       ├── error_view.dart   # error state + retry
│       └── loading_view.dart # spinner
└── main.dart                 # runApp(const App())
```

The dependency rule: **`presentation` → `domain` ← `data`.** The domain layer
imports nothing but Dart and `core`. Never let `data` import `presentation`, and
never put a `BuildContext` below the presentation layer.

Empty directories are held open by `.gitkeep` files. If you delete one, recreate
it or the folder disappears on the next clone.

---

## Core primitives

### `Failure` — `core/error/failure.dart`

A `sealed` class, so `switch` over it is exhaustive with no `default` branch.
Every failure carries a human-readable `message` and can be constructed with a
custom one.

| Subclass | Default message | Thrown when |
|---|---|---|
| `NetworkFailure` | No internet connection. | Socket/DNS failure |
| `TimeoutFailure` | Connection timed out. | Dio `connectTimeout` / `receiveTimeout` |
| `ServerFailure` | Server error. | 5xx — takes optional `statusCode` |
| `ParsingFailure` | Unexpected data from server. | `fromJson` throws or shape mismatch |
| `UnexpectedFailure` | Something went wrong. | Catch-all |

```dart
return const ServerFailure('Could not load profile.', 503);
```

### `Result<T>` — `core/error/result.dart`

Repositories and use cases return `Result<T>` so failures propagate as values
instead of thrown exceptions.

- `Ok<T>(value)` / `Err<T>(failure)`
- `isOk` / `isErr` getters
- `fold({required onOk, required onErr})` — collapse both branches to one value
- `getOrThrow()` — unwrap or throw; **use only at the framework edge**, i.e.
  inside a Riverpod `FutureProvider`, so the UI can render the error state

```dart
// In a repository — return the failure, don't throw.
Future<Result<User>> getUser(String id) async {
  try {
    final res = await _dio.get<Map<String, dynamic>>('/users/$id');
    return Ok(UserModel.fromJson(res.data!).toEntity());
  } on DioException catch (e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout => const Err(TimeoutFailure()),
      DioExceptionType.connectionError => const Err(NetworkFailure()),
      _ => Err(ServerFailure(e.message ?? 'Request failed.', e.response?.statusCode)),
    };
  }
}

// In a FutureProvider — throw, so AsyncValue.error drives the UI.
final userProvider = FutureProvider.autoDispose((ref) async {
  return (await ref.read(userRepositoryProvider).getUser('1')).getOrThrow();
});
```

### Presentation widgets

All three are stateless and centered, sized for a full-screen state branch.

- `LoadingView()` — `CircularProgressIndicator`
- `ErrorView(error: Object, onRetry: VoidCallback)` — icon, message, "Retry" button
- `EmptyView({String message, IconData icon})` — icon + message, both defaulted

Intended to sit inside a Riverpod `AsyncValue` branch:

```dart
final value = ref.watch(userProvider);
return value.when(
  loading: () => const LoadingView(),
  error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(userProvider)),
  data: (user) => user == null
      ? const EmptyView(message: 'No profile yet.')
      : ProfileBody(user: user),
);
```

---

## Included dependencies

| Package | Purpose |
|---|---|
| `dio` | HTTP client |
| `flutter_riverpod` | State management / DI |
| `go_router` | Declarative routing |
| `flutter_secure_storage` | Tokens, secrets |
| `shared_preferences` | Non-sensitive key-value storage |

All are declared up front so you don't lose time on dependency setup. Only
`go_router` is wired up so far (in `app/router.dart`); `dio`,
`flutter_riverpod`, `flutter_secure_storage`, and `shared_preferences` are
declared but not yet imported anywhere.

> If a package version conflicts later, run `flutter pub outdated`, then
> `flutter pub upgrade --major-versions` rather than hand-editing constraints.

---

## Verifying your setup

```bash
flutter pub get
flutter analyze      # expect: No issues found!
flutter test         # expect: All tests passed! (see step 3)
```
