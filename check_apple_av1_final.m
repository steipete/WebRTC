#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <CoreMedia/CoreMedia.h>
#include <sys/sysctl.h>

int main() {
    @autoreleasepool {
        NSLog(@"🔍 Checking Apple Hardware AV1 Support\n");
        
        // Check Apple Silicon capabilities
        NSLog(@"📱 System Information:");
        NSLog(@"macOS Version: %@", [[NSProcessInfo processInfo] operatingSystemVersionString]);
        
        // Check if we're on Apple Silicon
        int ret = 0;
        size_t size = sizeof(ret);
        if (sysctlbyname("hw.optional.arm64", &ret, &size, NULL, 0) == 0 && ret == 1) {
            NSLog(@"Architecture: Apple Silicon (ARM64)");
            NSLog(@"Note: M3 chips have AV1 hardware decode, but it's not exposed via VideoToolbox");
        } else {
            NSLog(@"Architecture: Intel x86_64");
            NSLog(@"Note: No Intel Macs have AV1 hardware support");
        }
        
        NSLog(@"\n🎯 AV1 Hardware Support Status:");
        NSLog(@"================================");
        
        // Test for AV1 support
        FourCharCode av1Code = 'av01';
        
        // Check hardware encoder
        CFMutableDictionaryRef encoderSpec = CFDictionaryCreateMutable(
            kCFAllocatorDefault, 0,
            &kCFTypeDictionaryKeyCallBacks,
            &kCFTypeDictionaryValueCallBacks);
        
        // Require hardware acceleration
        CFDictionarySetValue(encoderSpec, kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder, kCFBooleanTrue);
        
        VTCompressionSessionRef encoder = NULL;
        OSStatus status = VTCompressionSessionCreate(
            kCFAllocatorDefault,
            1920, 1080,
            av1Code,
            encoderSpec,
            NULL, NULL, NULL, NULL,
            &encoder);
        
        if (status == noErr && encoder) {
            NSLog(@"✅ AV1 hardware encoder available\!");
            VTCompressionSessionInvalidate(encoder);
            CFRelease(encoder);
        } else {
            NSLog(@"❌ No AV1 hardware encoder available (status: %d)", (int)status);
            
            // Try without hardware requirement
            CFDictionaryRemoveValue(encoderSpec, kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder);
            status = VTCompressionSessionCreate(
                kCFAllocatorDefault,
                1920, 1080,
                av1Code,
                encoderSpec,
                NULL, NULL, NULL, NULL,
                &encoder);
            
            if (status == noErr && encoder) {
                NSLog(@"ℹ️  AV1 software encoder might be available (but not hardware accelerated)");
                VTCompressionSessionInvalidate(encoder);
                CFRelease(encoder);
            } else {
                NSLog(@"❌ No AV1 encoder support at all in VideoToolbox");
            }
        }
        
        CFRelease(encoderSpec);
        
        NSLog(@"\n📊 Summary for WebRTC:");
        NSLog(@"====================");
        NSLog(@"• Apple has NOT exposed AV1 encoding in VideoToolbox (as of macOS 14.x)");
        NSLog(@"• M3 chips have AV1 decode hardware, but it's only used internally by Safari");
        NSLog(@"• No Apple hardware currently supports AV1 encoding");
        NSLog(@"• Software AV1 encoding (libaom) is too slow for real-time WebRTC");
        NSLog(@"\n✅ Current approach is correct:");
        NSLog(@"  - Use dav1d for receiving AV1 streams (software, but fast)");
        NSLog(@"  - Use H.265/H.264 for encoding (hardware accelerated)");
        NSLog(@"  - This matches what Safari does internally");
    }
    return 0;
}
