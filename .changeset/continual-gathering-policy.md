---
livekit_client: minor
---

RTCConfiguration.continualGatheringPolicy. Peer connections now gather ICE candidates continually by default, like the Swift, Android and JS SDKs, so a network change such as Wi-Fi to cellular produces new candidates without waiting for an ICE restart. Set RTCContinualGatheringPolicy.gatherOnce to keep the previous behavior.
