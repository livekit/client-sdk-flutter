# LiveKit Flutter Example

This app implements a video room using LiveKit's Flutter SDK. Designed to run for iOS, Android, Web, Mac, and Windows.

## Quickstart

Run example:

```bash
flutter pub get
# Due to the inconvenience of typing on mobile devices, 
# you can autofill URL and TOKEN for first run in debug mode.
flutter run --dart-define=URL=wss://${LIVEKIT_SERVER_IP_OR_DOMAIN} --dart-define=TOKEN=${YOUR_TOKEN}
```

## Using a token server

Instead of pasting a pre-generated token, the example can fetch credentials from a
[token server](https://docs.livekit.io/frontends/build/authentication/) at connect time,
the same way `TokenSource.endpoint(...)` and `TokenSource.developmentTokenServer(...)`
work in the JS and Rust SDKs:

1. Open **Connect Options** and enable **Server URL is token server**
2. In the **Token Server URL** field enter one of:
   - a token endpoint URL (e.g. `https://example.com/api/token`). The app POSTs a JSON
     token request to it and expects `server_url` and `participant_token` in the JSON response
   - your LiveKit Cloud sandbox app URL (e.g. `https://myproject-abc123.sandbox.livekit.io`)
   - your LiveKit Cloud **development token server ID** (e.g. `myproject-abc123`)
3. Enter a **Room Name** to join a specific room, or leave it empty to let the token server pick one
4. Press **Connect**

The last two use LiveKit Cloud's development token server
(`https://cloud-api.livekit.io/api/v2/sandbox/connection-details` with the `X-Sandbox-ID` header).
The Room Name field replaces the Token field while this option is enabled.

## End-to-End Encryption (E2EE)

The example app supports end-to-end encryption for audio and video tracks. To enable E2EE:

1. Toggle the "E2EE" switch in the connect screen
2. Enter a shared key that will be used for encryption
3. All participants must use the same shared key to communicate

For web support, you'll need to compile the E2EE web worker:

```bash
dart compile js web/e2ee.worker.dart -o example/web/e2ee.worker.dart.js -m
```

Note: All participants in the room must have E2EE enabled and use the same shared key to see and hear each other. If the keys don't match, participants won't be able to decode each other's audio and video.
