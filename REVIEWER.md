# In The Know — Campus Event Registration App Reviewer

This reviewer is based on the current Flutter source in `lib/`. It is written for a practical Q&A or project-defense session: explain the purpose, the flow, the important lines, and the reason behind each design choice.

## 1. Thirty-second project explanation

**In The Know** is a Flutter mobile application for browsing campus events and registering for them. Users create an account or log in through Firebase Authentication. After login, they can browse categorized events, view event details and available slots, complete a three-step registration form, see their registered events, mark an event as completed, and edit or delete their profile.

The app uses a simple separation of responsibilities:

- **Screens** display pages and collect user input.
- **Widgets** contain reusable visual components.
- **Models** describe structured data such as an event.
- **Services** contain Firebase/Auth/Firestore operations.
- **Data** contains the fixed event catalog.
- **Theme** contains shared colors.

The event descriptions, dates, images, locations, and slot limits are currently fixed in Dart. Firestore supplies live registration counts, user profiles, individual registrations, and the registered-events list.

## 2. Full user flow

```text
main()
  -> initialize Firebase
  -> run InTheKnowApp
  -> AuthGate
      -> LoadingPage while splash/auth state is waiting
      -> HomePage when a Firebase user exists
      -> LoginPage when no user exists

LoginPage -> Firebase Auth login -> AuthGate -> HomePage
RegisterPage -> Firebase Auth account + users/{uid} profile -> AuthGate -> HomePage
HomePage -> category filter -> event card -> EventDetailsPage
EventDetailsPage -> EventRegistrationPage
  Step 1: name + department
  Step 2: attendance type + date/time + agreement
  Step 3: confirmation
  -> Firestore transaction
  -> RegisteredEventsPage
```

## 3. File-by-file study guide

| File | Responsibility | Important things to say |
|---|---|---|
| `lib/main.dart` | App entry point, Firebase startup, auth routing | `WidgetsFlutterBinding.ensureInitialized`, `Firebase.initializeApp`, `MaterialApp`, `AuthGate` |
| `lib/firebase_options.dart` | Platform Firebase configuration | The current configuration is Android-only; unsupported platforms throw an error |
| `lib/models/event.dart` | Immutable event model and computed values | `final` fields, `const` constructor, getters, `withRegisteredCount` |
| `lib/data/event_catalog.dart` | Fixed event metadata | The catalog is the source for event identity/content; `findEvent` looks up by ID |
| `lib/services/auth_service.dart` | Firebase Authentication and user profile CRUD | Registration creates Auth account and `users/{uid}` profile |
| `lib/services/event_service.dart` | Firestore streams and registration transaction | The most important backend logic is in `registerForEvent` |
| `lib/theme/app_colors.dart` | Shared color constants | Avoids repeating brand colors throughout the screens |
| `lib/screens/loading_page.dart` | Splash/loading UI | Uses `TweenAnimationBuilder` for the progress animation |
| `lib/screens/login_page.dart` | Login form | Controllers, validation, loading state, Firebase error feedback |
| `lib/screens/register_page.dart` | Account/profile registration form | Creates the Auth user and profile document |
| `lib/screens/home_page.dart` | Event discovery | Firestore stream, category `ChoiceChip`s, carousel, event cards |
| `lib/screens/event_details_page.dart` | Event detail page | Live event count and registration status |
| `lib/screens/event_registration_page.dart` | Three-step registration form | Validates required fields before calling the service |
| `lib/screens/registered_events_page.dart` | User's registered events | Live list and `done` checkbox |
| `lib/screens/edit_profile_page.dart` | Profile viewing/editing/deletion | Read-only mode, save, email re-verification, delete confirmation |
| `lib/widgets/app_drawer.dart` | Side navigation drawer | Displays live user name/email and navigation callbacks |
| `lib/widgets/event_cover.dart` | Event image/fallback visual | Asset image, network image, or generated category cover |
| `lib/widgets/itk_bottom_nav.dart` | Reusable bottom navigation | Home, registered events, profile |
| `firestore.rules` | Database authorization rules | Ownership checks use Firebase Auth UID |
| `pubspec.yaml` | Dependencies and declared assets | Flutter, Firebase, Firestore, carousel slider, images |
| `test/widget_test.dart` | Basic widget test | Confirms the root app widget can be pumped |

## 4. `main.dart`: startup and authentication

### `main()`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const InTheKnowApp());
}
```

- `Future<void>` means startup is asynchronous and returns no value.
- `async` allows the function to use `await`.
- `WidgetsFlutterBinding.ensureInitialized()` makes sure Flutter's binding is ready before an asynchronous plugin operation.
- `Firebase.initializeApp(...)` connects the app to the configured Firebase project before any Firebase Auth or Firestore call.
- `runApp` places the root widget into Flutter's widget tree.

### `InTheKnowApp`

`StatelessWidget` is appropriate because this root widget does not own changing form or page state. `MaterialApp` provides:

- the app title;
- Material Design widgets;
- the global theme;
- the first page through `home: const AuthGate()`.

`ColorScheme.fromSeed` generates a consistent Material 3 color scheme from the green brand color. `debugShowCheckedModeBanner: false` removes the debug label.

### `AuthGate`

`AuthGate` is stateful because it stores `_splashDone`. Its `StreamBuilder<User?>` listens to `FirebaseAuth.instance.authStateChanges()`:

- `snapshot.connectionState == waiting`: Firebase is still checking the persisted login session.
- `!_splashDone`: keep showing the splash for at least 2.6 seconds.
- `snapshot.hasData`: a signed-in `User` exists, so show `HomePage`.
- otherwise show `LoginPage`.

`mounted` inside the delayed callback prevents `setState` after the widget has already been removed. This avoids a common Flutter lifecycle error.

## 5. Model and catalog

### `Event` model (`lib/models/event.dart`)

The class is an immutable data object. Its fields are `final`, so an event is not modified in place. Instead, the app creates a copy using:

```dart
event.withRegisteredCount(newCount)
```

This is useful because the catalog provides fixed data while Firestore provides the changing count.

Important computed getters:

- `slotsLeft`: `totalSlots - registeredCount`, clamped to zero so the UI never displays a negative number.
- `isFull`: true when registered count is greater than or equal to total slots.
- `slotsLabel`: converts the state into user-facing text such as `1 slot remaining`, `12 slots remaining`, or `Fully booked`.
- `dateLabel` and `timeLabel`: format the `DateTime` for display.

### `event_catalog.dart`

`kEventCatalog` is a top-level `final List<Event>`. It contains the five fixed events and their IDs, descriptions, categories, dates, locations, slot limits, and image asset paths.

The ID, such as `flutter-app-development`, is the stable key used in Firestore paths:

```text
events/{eventId}
events/{eventId}/registrations/{userUid}
users/{userUid}/registeredEvents/{eventId}
```

`findEvent` loops through the catalog and returns the matching event or `null`. Nullable return type `Event?` forces callers to handle the possibility that an ID is invalid.

## 6. Services and Firebase data flow

### Authentication service

`AuthService` centralizes Firebase operations so screens do not contain direct authentication implementation details.

#### Register

`createUserWithEmailAndPassword` creates the Firebase Auth identity. The returned `creds.user!.uid` is then used as the Firestore profile document ID:

```text
users/{uid}
  name
  role
  email
  phoneNumber
  createdAt
```

The exclamation mark in `creds.user!` is a null check assertion: after successful account creation, the code expects a user to exist.

#### Login and logout

- `signInWithEmailAndPassword` authenticates an existing user.
- `signOut` ends the session.
- `authStateChanges` is a stream used by `AuthGate` to react to login/logout automatically.

#### Update profile

The method updates the Firebase Auth email when it changed, using `verifyBeforeUpdateEmail`. This is safer than silently changing a login email because Firebase requires the new email to be verified. The Firestore profile is then updated with `SetOptions(merge: true)` so unrelated fields are preserved.

`TimeoutException` handling gives the user a useful message if the network operation takes too long.

#### Delete account

The method deletes `users/{uid}` first, then deletes the Firebase Auth account. In a production system, related registration documents should also be considered for cleanup or retention policy.

### Event service: read streams

`EventService` owns the Firestore instance and Auth instance.

#### `upcomingEvents()`

1. Listen to `events` with `snapshots()`.
2. Build a map from event ID to its Firestore `registeredCount`.
3. Map the fixed catalog into new `Event` objects with live counts.
4. Sort by date with `a.date.compareTo(b.date)`.

This hybrid design means event content is controlled in code while occupancy is live in Firestore.

#### `eventStream(eventId)`

Find the fixed base event, listen to `events/{eventId}`, read its count, and return a copy with the current count. If the ID is not in the catalog, it returns `Stream.value(null)`.

#### `isRegistered(eventId)`

The registration document ID is the current user's UID. `doc.exists` becomes a live boolean: existing means registered, missing means not registered.

#### `userProfile()` and `registeredEvents()`

Both listen to user-specific Firestore paths. `registeredEvents()` orders the user's subcollection by `date`, then adds `eventId` from the document ID into each returned map.

### The most important method: `registerForEvent`

The method performs these checks before writing:

1. A Firebase user must be signed in.
2. The event ID must exist in the fixed catalog.
3. The user's profile is read to provide a fallback name.

It creates three references:

```text
eventRef     = events/{eventId}
regRef       = events/{eventId}/registrations/{uid}
userRegRef   = users/{uid}/registeredEvents/{eventId}
```

Inside `runTransaction`:

1. Read `regRef`; if it exists, reject duplicate registration.
2. Read `eventRef` and get the latest count.
3. If `count >= totalSlots`, reject because the event is full.
4. Increment `registeredCount`, or create the event count document if it does not exist.
5. Store the registration record under the event.
6. Store a user-centered copy under `users/{uid}/registeredEvents`.

The transaction is important because the count is checked and updated atomically. If two users try to take the last slot, Firestore retries/conflict-checks the transaction rather than allowing both clients to overwrite the same count. The two registration records and count update are also committed as one transaction.

The `attendance` map uses conditional entries:

```dart
if (department != null) 'department': department,
```

This avoids writing optional fields when they are not supplied. `Timestamp.fromDate` converts Dart `DateTime` into a Firestore-compatible timestamp. `FieldValue.serverTimestamp()` uses the server's time instead of trusting the phone clock.

## 7. Page and widget explanations

### Loading page

`LoadingPage` is a `StatelessWidget` because it only renders its inputs. `TweenAnimationBuilder<double>` animates a value from `0.08` to `1.0`; `FractionallySizedBox` uses that value as the progress width. `SafeArea` prevents content from colliding with notches or system bars.

### Login and register pages

They are `StatefulWidget`s because they own:

- `TextEditingController`s;
- password visibility state;
- loading state;
- selected role/country code.

Important practices:

- `controller.text.trim()` removes accidental leading/trailing spaces.
- Required fields are checked before any network request.
- `_loading` disables/replaces the submit action during the request.
- `try/catch/finally` shows errors and restores the loading state.
- `dispose()` releases controllers when the page is removed.
- `mounted` protects UI updates after an asynchronous operation.
- `obscureText` hides the password.
- `DropdownButtonFormField` limits role and country-code input to known choices.

After successful registration, `Navigator.pop(context)` returns to the login page. The auth-state stream then determines the next screen after the user logs in.

### Home page

`HomePage` listens to `_eventsStream` with `StreamBuilder<List<Event>>`:

- error state displays an error message;
- no data displays a spinner;
- data builds the carousel.

`ChoiceChip` changes `_category` through `setState`. The carousel filters the list using a case-insensitive category comparison. `ValueKey(_category)` tells Flutter the carousel content changed when the category changes.

`CarouselSlider.builder` creates cards lazily. `GestureDetector` handles taps and navigates to `EventDetailsPage(eventId: event.id)`.

### Event details page

The page receives an `eventId`, not a whole event object, so it can subscribe to the latest count. It has two streams:

- `_eventStream`: event metadata plus live occupancy;
- `_registeredStream`: whether this user has registered.

The register button has three states:

1. `You're registered ✓`: disabled if the user already registered.
2. `Fully booked`: disabled if no slots remain.
3. `Register for this Event`: enabled when registration is allowed.

The full condition is `event.isFull && !registered`; this keeps the registered user's status visible even if the event later becomes full.

`EventCover` displays the event asset. If the asset fails, it falls back to a generated gradient/icon cover.

### Event registration page

The page receives the selected `Event` through its constructor. `_step` is a small state machine:

- `0`: Your Information;
- `1`: Attendance Options;
- `2`: success/confirmation.

`_loadProfile` pre-fills name and email from Firestore/Auth. Email is read-only during registration because it comes from the authenticated account.

`_continueFromInfo` requires a non-empty name and department before moving to step 1. `_confirm` requires an attendance date/time and agreement to the guidelines before calling `registerForEvent`.

`showDialog<DateTime>` opens `_DateTimeDialog`, which combines `CalendarDatePicker` and `showTimePicker`, then returns one `DateTime` to the parent page.

### Registered events page

The page listens to `registeredEvents()`. Each record becomes a `CheckboxListTile`. Checking it calls `setRegisteredEventDone`, which merges `{done: true/false}` into the registration document. Completed events use the green text color.

`Timestamp.toDate()` converts Firestore timestamps back into Dart `DateTime` for display.

### Edit profile page

The page loads the profile once with `_eventService.userProfile().first`, fills the controllers, and initially displays read-only fields. `_editing` controls whether fields and dropdowns accept input.

The save process validates all fields, calls `AuthService.updateProfile`, and handles:

- Firebase errors;
- `requires-recent-login` for sensitive email changes;
- generic/network errors;
- loading state.

Account deletion first presents an `AlertDialog` confirmation. `Navigator.popUntil(... route.isFirst)` returns to the auth gate after deletion/logout.

### Reusable widgets

#### `ItkBottomNav`

Accepts `currentIndex` and `ValueChanged<int> onTap`, making it reusable on several pages. `BottomNavigationBar` has three items, but labels are hidden for the compact pill design. The parent page decides what each tap does.

#### `AppDrawer`

Accepts callbacks instead of owning navigation logic. This is a good separation: the drawer only reports what the user chose, while each page decides whether to push, replace, or pop routes.

#### `EventCover`

Uses this fallback order:

1. local asset if `imageAsset` is present;
2. network image if `imageUrl` is present;
3. generated cover if no image is available or an image fails.

#### `AppColors`

The static `Color` constants keep the visual identity consistent and make future color changes easier.

## 8. Firestore structure and security rules

The current logical data model is:

```text
users/{uid}
  name, role, email, phoneNumber, createdAt/updatedAt

users/{uid}/registeredEvents/{eventId}
  eventId, title, category, location, date,
  department, attendanceType, attendanceAt,
  done, registeredAt

events/{eventId}
  registeredCount, totalSlots, title

events/{eventId}/registrations/{uid}
  uid, name, email, department, attendanceType,
  attendanceAt, registeredAt
```

Rules helpers:

- `signedIn()` returns `request.auth != null`.
- `isOwner(userId)` verifies the request UID matches the path UID.

Current permissions:

- users are readable/writable only by the owner;
- a user's registered-event documents may be read/created/updated by that owner, but not deleted;
- events are readable by signed-in users and currently allow signed-in users to create/update;
- event registration documents are readable/created only by the user whose UID is the document ID;
- registration update/delete is disabled.

### Security caveat to mention if asked

The client transaction prevents normal duplicate and over-capacity registrations, but the rules currently allow any signed-in user to create/update an `events/{eventId}` document. A stronger production design would restrict event count writes to a trusted backend/admin role or enforce field-level invariants in rules. Also, the app has no cancellation flow, matching the rule that registration documents cannot be deleted.

## 9. Common Flutter terms you should be able to explain

- **Widget**: an immutable description of part of the UI.
- **StatelessWidget**: renders from inputs and has no mutable local state.
- **StatefulWidget**: has a separate `State` object that can change with `setState`.
- **BuildContext**: location of a widget in the tree; used to access theme, navigator, media query, and scaffold messenger.
- **`build()`**: describes what the UI should look like for the current state.
- **`setState()`**: marks the state as changed and schedules a rebuild.
- **`const`**: compile-time constant; reduces unnecessary object creation when possible.
- **`final`**: assigned once at runtime; the object itself may still be mutable unless it is immutable.
- **`late final`**: initialized once after declaration, useful for streams that need `widget` values after state creation.
- **`Stream`**: asynchronous sequence of values, suitable for live Firestore updates.
- **`Future`**: one eventual asynchronous result, suitable for login or save operations.
- **`StreamBuilder`**: rebuilds UI when a stream emits or changes state.
- **`TextEditingController`**: reads and changes a text field's value.
- **`Navigator.push`**: adds a route to the stack.
- **`Navigator.pop`**: returns to the previous route.
- **`Navigator.popUntil`**: removes routes until a condition is true.
- **`SafeArea`**: avoids system UI overlap.
- **`SingleChildScrollView`**: allows a page to scroll when content is taller than the screen.
- **`Expanded`**: takes remaining space in a `Row` or `Column`.
- **`Padding`/`SizedBox`**: layout spacing.
- **`Container`/`BoxDecoration`**: backgrounds, borders, rounded corners, and shadows.
- **`GestureDetector`/`InkWell`**: touch interaction.

## 10. Likely Q&A questions and model answers

### Why did you use Flutter?

Flutter lets us build the mobile UI with Dart and a single widget-based codebase. Its hot reload, Material widgets, layout system, and Firebase packages make it suitable for a campus mobile app.

### Why are some widgets stateful and others stateless?

Pages with changing input or UI state—forms, loading status, selected filters, registration steps—are stateful. Reusable visual components that only render supplied values—event cover, bottom nav, drawer items—are stateless.

### Why do you use `StreamBuilder`?

Firestore `snapshots()` produces live streams. `StreamBuilder` automatically rebuilds the relevant UI when counts, profiles, or registrations change, while also providing loading and error states.

### How do you stop duplicate registration?

The registration document ID is the user's UID. The transaction first reads that document and throws if it already exists. The UI also listens to the document and disables the button after registration.

### How do you stop the event from exceeding its capacity?

The transaction reads the latest `registeredCount`, compares it with `totalSlots`, and increments only if capacity remains. Because the read/check/write is transactional, concurrent attempts are conflict-checked.

### Why store registration data in two places?

`events/{eventId}/registrations/{uid}` is event-centered and useful for organizers. `users/{uid}/registeredEvents/{eventId}` is user-centered and makes the user's event list easy to query. The transaction keeps both copies synchronized at creation time.

### Why is the event catalog hard-coded?

The current version treats the five events as fixed app content, while Firestore stores mutable registration counts and user-specific records. A future admin feature could move event metadata to Firestore.

### What happens if Firebase is offline or fails?

The screens catch errors and show a `SnackBar` or an inline error message. The loading state is reset in `finally` blocks. Firestore may cache or queue some operations depending on platform settings, but the app should still be tested with network failures.

### Why use `mounted`?

An async operation may finish after the page has been removed. Checking `mounted` ensures `setState`, snackbars, or navigation are not attempted with an invalid widget context.

### What is the difference between Auth and Firestore?

Firebase Auth stores and verifies the login identity, email, and password. Firestore stores application profile and event data. The Auth UID links the two systems.

### How is user data protected?

Firestore rules compare `request.auth.uid` with the UID in the path. This prevents one signed-in user from accessing another user's profile or registered-event collection. Event count-write permissions need stronger restriction for a production release.

### What is the role of `dispose()`?

It releases `TextEditingController`s when a state object is removed, preventing resource leaks and stale listeners.

### Why use `serverTimestamp()`?

It records the backend server time, which is more trustworthy and consistent than a potentially incorrect device clock.

### Why use `Timestamp.fromDate()`?

Firestore stores timestamps in its own timestamp type. The conversion persists a Dart `DateTime` in a queryable Firestore-compatible form.

### What is a transaction?

A transaction groups reads and writes with conflict detection. If a value read by the transaction changes before commit, Firestore retries or fails it, protecting the slot count from race conditions.

### What would you improve next?

I would add an admin event-management flow, move event metadata to Firestore, restrict event writes to admins or Cloud Functions, add registration cancellation with a safe count decrement, improve validation for email/phone/password, add more tests, and support iOS/web Firebase configurations.

## 11. Important limitations and talking points

These are not necessarily demo blockers, but be ready to explain them honestly:

1. **Android-focused Firebase configuration:** `firebase_options.dart` throws for iOS, web, Windows, macOS, and Linux because only Android options are configured.
2. **Event metadata is not live:** title/date/location/slot limit come from `kEventCatalog`; only counts come from Firestore.
3. **No cancellation:** the UI lets a user mark an event done, not unregister. This matches the current rule denying registration deletion.
4. **Permissions can be hardened:** any signed-in client can currently write the event count document according to `firestore.rules`.
5. **Test coverage is minimal:** the current widget test only checks that `InTheKnowApp` can be pumped; it does not test Firebase flows or registration concurrency.
6. **Email change behavior:** Firebase may require a recent login for sensitive account changes; the app catches and explains that error.
7. **Asset naming:** the declared launcher image in `pubspec.yaml` uses `ITK_logo.png`, while the listed asset is `itk_logo.png`. Windows is case-insensitive, but Android/Linux-style build environments can be case-sensitive, so this should be made consistent.

## 12. Demo script for the Q&A session

1. Start at the splash screen and explain `AuthGate`.
2. Register a sample account and point out Auth versus Firestore profile storage.
3. Log in and show the Home page's live event stream.
4. Tap a category chip and explain `setState` plus filtering.
5. Open an event and explain live count plus registration status.
6. Complete step 1 and explain validation.
7. Complete step 2, choose attendance details, agree to the guidelines, and confirm.
8. Explain the transaction and show the success screen.
9. Open Registered Events and check an event as done.
10. Open Profile, edit a field, save, and explain `merge: true`.
11. Mention the security caveat and the next improvements without hiding them.

## 13. Final memorization checklist

Before the Q&A, be able to say these without reading:

- The app is Flutter/Dart with Firebase Auth and Cloud Firestore.
- `AuthGate` chooses loading, home, or login from `authStateChanges()`.
- The event catalog is fixed; Firestore supplies live counts and registrations.
- `EventService` keeps Firebase logic out of the UI.
- Registration uses a transaction to prevent duplicates and overbooking.
- Registration writes an event-centered record and a user-centered record.
- `StreamBuilder` is used for real-time UI; `Future` is used for one-time actions.
- `setState` updates local UI state; `Navigator` changes pages.
- `mounted` protects async UI updates; `dispose` releases controllers.
- Firestore rules use the Auth UID for ownership.
- The main production improvement is to restrict event-count writes to trusted admin/backend code.
