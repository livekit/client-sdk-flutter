---
livekit_client: patch
---

A full reconnect requested while a reconnect attempt is parked waiting for connectivity is now honored by that attempt instead of the one after it. `attemptReconnect` captured resume-vs-full before a wait that runs for up to ten connection timeouts, so a peer connection that failed partway through an outage raised an escalation the attempt coming out of the wait could not act on, and one doomed resume went out first
