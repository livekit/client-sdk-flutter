PROTO_DIR="../protocol/protobufs"

proto:
	@{ \
	if [ -d "$(PROTO_DIR)" ]; \
	then \
		protoc --dart_out=lib/src/proto -I$(PROTO_DIR) $(PROTO_DIR)/livekit_rtc.proto $(PROTO_DIR)/livekit_models.proto $(PROTO_DIR)/livekit_metrics.proto; \
	else \
		echo "../protocol/protobufs is not found. github.com/livekit/protocol must be checked out"; \
	fi \
	}

format:
	dart format lib/src/proto

e2ee: dart compile js ./web/e2ee.worker.dart -o ./example/web/e2ee.worker.dart.js

.PHONY: proto format
