---
livekit_client: patch
---

A track that fails to republish after a full reconnect no longer leaves the tracks after it unpublished or the room without a `RoomReconnectedEvent`. The failure is logged, the track is reported with a `LocalTrackUnpublishedEvent`, and the remaining tracks are republished
