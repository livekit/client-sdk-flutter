---
livekit_client: patch
---

Building a publisher offer and applying an answer now take turns on each connection, so an offer requested while an answer is being applied is always sent, whatever order the platform delivers its replies in
