#import "LiveKitClientPlugin.h"
#if __has_include(<livekit_client/livekit_client-Swift.h>)
#import <livekit_client/livekit_client-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "livekit_client-Swift.h"
#endif

@implementation LiveKitClientPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftLiveKitClientPlugin registerWithRegistrar:registrar];
}
@end
