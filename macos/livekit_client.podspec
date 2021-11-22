#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint livekit_client.podspec` to validate before publishing.
#
# Pod::Spec.new do |s|
#   s.name             = 'livekit_client'
#   s.version          = '0.0.1'
#   s.summary          = 'A new flutter plugin project.'
#   s.description      = <<-DESC
# A new flutter plugin project.
#                        DESC
#   s.homepage         = 'http://example.com'
#   s.license          = { :file => '../LICENSE' }
#   s.author           = { 'Your Company' => 'email@example.com' }
#   s.source           = { :path => '.' }
#   s.source_files     = 'Classes/**/*'
#   s.dependency 'FlutterMacOS'

#   s.platform = :osx, '10.11'
#   s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
#   s.swift_version = '5.0'
# end

#
# LiveKit
# https://livekit.io/
# https://github.com/livekit
#

Pod::Spec.new do |s|
  s.name                = 'livekit_client'
  s.version             = '0.5.3'
  s.summary             = 'Open source platform for real-time audio and video.'
  s.description         = 'Open source platform for real-time audio and video.'
  s.homepage            = 'https://livekit.io/'
  s.license             = { :file => '../LICENSE' }
  s.author              = { 'LiveKit' => 'contact@livekit.io' }
  s.source              = { :path => '.' }
  s.source_files        = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.platform            = :osx, '10.11'
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version       = '5.0'
  s.static_framework    = true

  s.dependency 'FlutterMacOS'
  s.dependency 'WebRTC-SDK', '~> 92.4515'
end
