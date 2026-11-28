---
livekit_client: patch
---

Mark SDK plumbing members such as `LocalVideoTrack.subscribedCodecs`, the `prevStats` fields of tracks and the proto conversions of `RpcError` as `@internal`, so the analyzer warns when an app uses them.
