---
livekit_client: patch
---

On web, `AudioCaptureOptions` with a `deviceId` now apply `echoCancellation`, `noiseSuppression` and `autoGainControl`; before, they were left out and the browser kept its defaults
