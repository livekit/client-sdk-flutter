---
livekit_client: patch
---

A resume now waits until the publisher has finished its ICE restart before the room reports it reconnected, so reliable data sent right after a node migration is no longer lost, and a publisher that cannot reconnect leads to a full reconnect instead of repeated resumes.
