#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <CoreMedia/CoreMedia.h>

int main() {
    @autoreleasepool {
        NSLog(@"🔍 Checking Apple AV1 Support in VideoToolbox\n");
        
        // Check for AV1 codec constants
        NSLog(@"📌 Checking for AV1 codec type constants:");
        
        // Known codec types
        NSLog(@"H.264: %d", kCMVideoCodecType_H264);
        NSLog(@"H.265: %d", kCMVideoCodecType_HEVC);
        
        // Check if AV1 constant exists (it would be something like kCMVideoCodecType_AV1)
        // As of macOS 14, Apple has not exposed AV1 in VideoToolbox
        
        // Try common AV1 FourCC codes
        FourCharCode av1_codes[] = {
            'av01',  // Standard AV1 fourcc
            'AV01',
            'av1c',
            'AV1C'
        };
        
        NSLog(@"\n📊 Testing potential AV1 codec identifiers:");
        
        for (int i = 0; i < 4; i++) {
            // Test encoder
            CFMutableDictionaryRef encoderConfig = CFDictionaryCreateMutable(
                kCFAllocatorDefault, 0,
                &kCFTypeDictionaryKeyCallBacks,
                &kCFTypeDictionaryValueCallBacks);
            
            CFDictionarySetValue(encoderConfig, kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder, kCFBooleanTrue);
            
            VTCompressionSessionRef encoder = NULL;
            OSStatus status = VTCompressionSessionCreate(
                kCFAllocatorDefault,
                1920, 1080,
                av1_codes[i],
                encoderConfig,
                NULL, NULL, NULL, NULL,
                &encoder);
            
            if (status == noErr && encoder) {
                NSLog(@"✅ AV1 encoder might be available with code: '%c%c%c%c'",
                    (av1_codes[i] >> 24) & 0xFF,
                    (av1_codes[i] >> 16) & 0xFF,
                    (av1_codes[i] >> 8) & 0xFF,
                    av1_codes[i] & 0xFF);
                VTCompressionSessionInvalidate(encoder);
                CFRelease(encoder);
            } else {
                NSLog(@"❌ No encoder for code: '%c%c%c%c' (status: %d)",
                    (av1_codes[i] >> 24) & 0xFF,
                    (av1_codes[i] >> 16) & 0xFF,
                    (av1_codes[i] >> 8) & 0xFF,
                    av1_codes[i] & 0xFF,
                    (int)status);
            }
            
            CFRelease(encoderConfig);
            
            // Test decoder
            VTDecompressionSessionRef decoder = NULL;
            CMVideoFormatDescriptionRef formatDesc = NULL;
            
            OSStatus formatStatus = CMVideoFormatDescriptionCreate(
                kCFAllocatorDefault,
                av1_codes[i],
                1920, 1080,
                NULL,
                &formatDesc);
            
            if (formatStatus == noErr && formatDesc) {
                CFMutableDictionaryRef decoderConfig = CFDictionaryCreateMutable(
                    kCFAllocatorDefault, 0,
                    &kCFTypeDictionaryKeyCallBacks,
                    &kCFTypeDictionaryValueCallBacks);
                
                VTDecompressionOutputCallbackRecord callback = {0};
                
                status = VTDecompressionSessionCreate(
                    kCFAllocatorDefault,
                    formatDesc,
                    decoderConfig,
                    NULL,
                    &callback,
                    &decoder);
                
                if (status == noErr && decoder) {
                    NSLog(@"✅ AV1 decoder might be available with code: '%c%c%c%c'",
                        (av1_codes[i] >> 24) & 0xFF,
                        (av1_codes[i] >> 16) & 0xFF,
                        (av1_codes[i] >> 8) & 0xFF,
                        av1_codes[i] & 0xFF);
                    VTDecompressionSessionInvalidate(decoder);
                    CFRelease(decoder);
                }
                
                CFRelease(formatDesc);
                CFRelease(decoderConfig);
            }
        }
        
        NSLog(@"\n📱 Platform Information:");
        NSLog(@"macOS Version: %@", [[NSProcessInfo processInfo] operatingSystemVersionString]);
        NSLog(@"Architecture: %s", NXGetLocalArchInfo()->name);
        
        NSLog(@"\n📚 Summary:");
        NSLog(@"As of macOS 14.x, Apple has NOT exposed AV1 support in VideoToolbox");
        NSLog(@"While Safari can decode AV1 (using dav1d), there's no public API for encoding");
        NSLog(@"Apple Silicon Macs have the hardware capability, but it's not exposed to developers");
    }
    return 0;
}
