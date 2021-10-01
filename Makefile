PROTO_DIR="../protocol"

proto:
	@{ \
	if [ -d "$(PROTO_DIR)" ]; \
	then \
		protoc --dart_out=lib/src/proto -I$(PROTO_DIR) $(PROTO_DIR)/livekit_rtc.proto $(PROTO_DIR)/livekit_models.proto; \
	else \
		echo "../protocol is not found. github.com/livekit/protocol must be checked out"; \
	fi \
	}

format:
	flutter format --set-exit-if-changed -l 100 .

.PHONY: proto format
