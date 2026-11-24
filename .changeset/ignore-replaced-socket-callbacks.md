---
livekit_client: patch
---

A late close from a signal socket the SDK already replaced no longer starts another reconnect. In a browser it arrives up to seconds later, which made a room resume every 2 s after its first reconnect
