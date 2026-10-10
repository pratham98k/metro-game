# Little Bullet Express 🚄

A colorful Flutter train game for children aged **4–5**. Drive a friendly bullet train through sunny meadows, a sparkling bay, and peach-colored mountains. Switch tracks, collect eight stars, and earn an explorer badge.

The challenge is matching the train’s track to the approaching star. The train moves automatically; missed stars simply roll past and new ones arrive. There are no crashes, lost points, countdowns, ads, accounts, purchases, or analytics.

## Run on your Mac with Docker

You do **not** need Flutter, Dart, Xcode, or Node installed on your Mac.

1. Install and open [Docker Desktop for Mac](https://docs.docker.com/desktop/setup/install/mac-install/).
2. Open Terminal in this project folder.
3. Run:

   ```sh
   docker compose up --build -d game
   ```

4. Open **[http://localhost:8080](http://localhost:8080)** in Chrome, Safari, or another modern browser.

The first build downloads the Flutter toolchain and can take several minutes. Later builds reuse Docker’s cache. Allow several GB of Docker disk space and approximately 4 GB of available Docker memory. Internet access is needed for the initial build; the built game serves its artwork, sound generator, fonts, and CanvasKit renderer locally.

Docker runs the **Flutter web build**, which you play in your Mac’s browser. It does not run a macOS or iOS GUI inside a container.

### Apple Silicon and Intel

The Compose file explicitly uses `linux/amd64`, including on Apple Silicon. This keeps the pinned Flutter Linux toolchain consistent on both Mac architectures. M-series Macs use Docker Desktop’s amd64 emulation, so the first build is slower. If you encounter an `exec format error`, check that Docker Desktop supports amd64 emulation; update Docker Desktop if needed.

### Useful commands

```sh
# See status and health
 docker compose ps

# Read server logs
 docker compose logs -f game

# Rebuild after changing Dart code
 docker compose up --build -d game

# Stop and remove the project's containers
 docker compose down

# Use another port if 8080 is occupied
 PORT=8081 docker compose up --build -d game
```

The server binds only to your Mac’s loopback address. With a custom port, open `http://localhost:8081` instead.

## How to play

1. Choose **Sunny Meadows**, **Bubble Bay**, or **Peachy Peaks**.
2. Press **Let’s ride!** The train starts moving by itself.
3. Tap an approaching star’s track, or use the large **Track 1 / 2 / 3** buttons.
4. Collect **8 stars** to earn that world’s badge.
5. Ride again, choose another world, or take a break!

| Control | Action |
| --- | --- |
| Tap a track / track button | Move to that track |
| ↑ / ↓ | Move one track up / down |
| 1 / 2 / 3 | Choose a track directly |
| B / “Toot toot!” | Ring a cheerful bell |
| P / Esc / pause button | Pause or resume |
| Speaker button | Mute or enable sound |
| Pace button | Switch between Gentle and Zippy |

Keyboard shortcuts work while the game has focus. Tap the game or a track button to return focus to it. World selection is disabled during an active or paused ride; pause and choose **Back to station** to change worlds.

### Designed for little conductors

- Large track buttons, visual star targets, and generous collection zones.
- Gentle speed by default, with an optional faster challenge.
- Repeatable star patterns to support practice and anticipation.
- Positive feedback and one badge per world; no losing state.
- Pause when the application loses focus or becomes inactive; resume explicitly.
- A short help screen and a grown-up guide inside the game.
- Locally synthesized, low-volume sounds with a mute control.
- Badges are **session-only**: reloading or closing the page clears them. No personal information or progress is stored.

A grown-up should demonstrate the first ride. The instructions use text, so independent reading is not assumed. The game has accessible button labels and keyboard controls, but the moving-track challenge remains visual and is not a complete nonvisual game experience. Sound requires a browser gesture and may be unavailable under restrictive browser settings; visual feedback works without it.

## Test and validate with Docker

```sh
docker compose --profile test run --build --rm test
```

This checks Dart formatting, runs `flutter analyze`, and runs all unit and widget tests with coverage. A nonzero exit code indicates a failure. Coverage from this command lives inside the disposable test container; use the mounted development command below to save it locally.

The tests cover:

- Star pickup, no duplicate scoring, and missed-star behavior.
- Pause/resume, lane bounds, pace changes, and long-frame clamping.
- Completion at exactly eight stars and badge retention between rides.
- World reset, desktop play controls, mobile layout, and help navigation.

### Develop without installing Flutter

Build the development toolchain image, then mount this folder:

```sh
docker build --platform linux/amd64 --target sdk -t little-bullet-sdk .

docker run --rm --platform linux/amd64 \
  -v "$PWD:/app" little-bullet-sdk \
  sh -c 'flutter pub get && dart format lib test && flutter analyze && flutter test --coverage'
```

The mount lets formatting changes and `coverage/lcov.info` appear in your project. Rebuild the game image after editing to update the release browser preview. The default Docker server is a release preview, not a hot-reload server.

### Develop with a local Flutter SDK

The project is tested with **Flutter 3.35.7 / Dart 3.9.2**. Docker pins this Flutter release; `pubspec.lock` pins package resolution. See the official [Flutter installation guide](https://docs.flutter.dev/install) and [web development guide](https://docs.flutter.dev/platform-integration/web/setup).

```sh
flutter pub get
flutter run -d chrome

dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter build web --release --no-web-resources-cdn
```

Only the web platform is scaffolded. Native Android/iOS/macOS packaging is outside this project’s current scope; the shared game and UI are Flutter, and the audio implementation uses a conditional web adapter with a silent native fallback.

## Project structure

```text
assets/fonts/                 Bundled Roboto fonts and their license
lib/
  main.dart                   App entry point and theme
  game/
    game_controller.dart      Game state, scoring, pace, and progression
    sound.dart                Conditional audio adapter export
    sound_web.dart            Browser audio bridge
    sound_stub.dart           Silent non-web fallback
  ui/
    game_screen.dart          Responsive UI, inputs, lifecycle, and dialogs
    landscape.dart            Original vector scenery and train painter
test/
  game_controller_test.dart   Deterministic game-rule tests
  widget_test.dart            Interaction and responsive-layout tests
web/
  index.html                  Loading shell and metadata
  flutter_bootstrap.js        Local renderer setup
  sound.js                    Small Web Audio synthesizer
  favicon.svg                 Train icon
docker/nginx.conf             Static-server configuration
Dockerfile                   SDK, test, build, and unprivileged server stages
compose.yaml                 Local game and test services
.github/workflows/ci.yml      Automated checks and release-image build
```

## Engineering decisions

- **Separate rules from rendering.** `GameController` owns the ride state; UI code forwards user actions. The painter draws the model without mutating it.
- **Deterministic updates.** The UI supplies elapsed time. Tests drive the same rules without sleeps, randomness, or real timers. Frame deltas are capped so a suspended browser cannot skip the whole ride.
- **Explicit state machine.** Ready → riding → paused/resumed or complete. A reset returns to the station, preserving badges for the session.
- **Scoped updates.** A `Listenable` repaints the landscape during a ride. The surrounding UI rebuilds only when visible state such as score, lane, phase, world, or pace changes.
- **Resource cleanup.** The ticker, focus node, lifecycle observer, and controller are disposed with the screen.
- **Minimal dependencies.** No third-party runtime packages. Artwork is drawn with Flutter Canvas, and sound is synthesized in the browser.
- **Reproducible tooling.** A pinned Flutter toolchain, committed lockfile, lint rules, tests, CI, and a multi-stage Docker build keep the development workflow explicit. Base images use version tags; they are not fully digest-pinned.
- **Small production surface.** Only compiled web files and an unprivileged Nginx server ship in the final image. No Flutter SDK or source code is needed at runtime.

### Customization

Change the world names and star target in `game_controller.dart`. Adjust the pace, spawn interval, and collection window there as well. Edit `landscape.dart` for colors, scenery, or train styling. Keep the visible “8 stars” copy and tests in sync if changing the target. Run formatting, analysis, and tests after edits.

## Manual play checklist

- Start each world and collect eight stars; verify the correct badge.
- Miss a star; confirm new stars keep coming without losing points.
- Try touch/click controls, keyboard controls, and both paces.
- Pause and resume; switch tabs and return to confirm automatic pause.
- Toggle sound and ring the bell after clicking the game.
- Resize to a narrow phone window and check all controls remain reachable.
- Refresh and confirm the documented session-only badge behavior.

## Troubleshooting

| Symptom | What to do |
| --- | --- |
| Cannot connect to the Docker daemon | Open Docker Desktop and wait until its engine is running. |
| Port already allocated | Use `PORT=8081 docker compose up --build -d game`. |
| First build appears slow | SDK downloads and amd64 emulation take time. Keep Docker running; subsequent builds use the cache. |
| Dependency download fails | Check your connection, proxy, and Docker network access, then retry. |
| Old version appears after rebuilding | Reload the page; if necessary, do a hard refresh. |
| Blank page | Check `docker compose logs game`, `/health`, and the browser console. Use a browser with WebAssembly support. |
| No sound | Click Let’s ride or Toot toot, enable the speaker toggle, and check system/browser audio. |
| Need a clean rebuild | Run `docker compose build --no-cache game`, then `docker compose up -d game`. This downloads dependencies again. |

Roboto is redistributed under its included Apache 2.0 license in `assets/fonts/Roboto_LICENSE.txt`. The train and scenery are original Canvas drawings created for this project.

Flutter’s [web deployment documentation](https://docs.flutter.dev/deployment/web) describes the release build used here.
