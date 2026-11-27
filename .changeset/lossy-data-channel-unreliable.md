---
livekit_client: minor
---

Data published with reliable: false is now sent without retransmission. The lossy data channel was created with maxRetransmits 0, but the value did not reach the platform, so its packets were retransmitted until delivered
