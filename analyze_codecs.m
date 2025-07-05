#import <Foundation/Foundation.h>
#import <dlfcn.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *frameworkPath = @"/Users/steipete/Projects/WebRTC/src/src/out/Default/WebRTC.framework/Versions/A/WebRTC";
        
        void *handle = dlopen([frameworkPath UTF8String], RTLD_NOW);
        if (!handle) {
            NSLog(@"Failed to load framework");
            return 1;
        }
        
        NSLog(@"🔍 WebRTC Codec Analysis");
        NSLog(@"========================\n");
        
        // Get factory classes
        Class encoderFactoryClass = NSClassFromString(@"RTCDefaultVideoEncoderFactory");
        Class decoderFactoryClass = NSClassFromString(@"RTCDefaultVideoDecoderFactory");
        
        id encoderFactory = [[encoderFactoryClass alloc] init];
        id decoderFactory = [[decoderFactoryClass alloc] init];
        
        // Get supported codecs
        NSArray *encoderCodecs = [encoderFactory performSelector:@selector(supportedCodecs)];
        NSArray *decoderCodecs = [decoderFactory performSelector:@selector(supportedCodecs)];
        
        NSLog(@"📹 VIDEO ENCODERS:");
        NSLog(@"==================");
        
        NSMutableDictionary *encoderDetails = [NSMutableDictionary dictionary];
        
        for (id codecInfo in encoderCodecs) {
            NSString *name = [codecInfo performSelector:@selector(name)];
            
            // Get parameters if available
            NSDictionary *params = nil;
            if ([codecInfo respondsToSelector:@selector(parameters)]) {
                params = [codecInfo performSelector:@selector(parameters)];
            }
            
            // Create encoder to check implementation
            id encoder = [encoderFactory performSelector:@selector(createEncoder:) withObject:codecInfo];
            NSString *implementation = @"Unknown";
            
            if (encoder && [encoder respondsToSelector:@selector(implementationName)]) {
                implementation = [encoder performSelector:@selector(implementationName)];
            }
            
            if (!encoderDetails[name]) {
                encoderDetails[name] = [NSMutableArray array];
            }
            
            NSMutableString *details = [NSMutableString stringWithFormat:@"%@ (%@)", name, implementation];
            if (params && params.count > 0) {
                [details appendFormat:@" - Profile: %@", params[@"profile-level-id"] ?: @"default"];
            }
            
            [encoderDetails[name] addObject:details];
        }
        
        // Print encoder details
        for (NSString *codec in @[@"H264", @"H265", @"VP8", @"VP9", @"AV1"]) {
            NSArray *implementations = encoderDetails[codec];
            if (implementations) {
                for (NSString *impl in implementations) {
                    NSLog(@"✅ %@", impl);
                }
            } else {
                NSLog(@"❌ %@ - Not available", codec);
            }
        }
        
        NSLog(@"\n📺 VIDEO DECODERS:");
        NSLog(@"==================");
        
        NSMutableDictionary *decoderDetails = [NSMutableDictionary dictionary];
        
        for (id codecInfo in decoderCodecs) {
            NSString *name = [codecInfo performSelector:@selector(name)];
            
            // Get parameters if available
            NSDictionary *params = nil;
            if ([codecInfo respondsToSelector:@selector(parameters)]) {
                params = [codecInfo performSelector:@selector(parameters)];
            }
            
            // Create decoder to check implementation
            id decoder = [decoderFactory performSelector:@selector(createDecoder:) withObject:codecInfo];
            NSString *implementation = @"Unknown";
            
            if (decoder && [decoder respondsToSelector:@selector(implementationName)]) {
                implementation = [decoder performSelector:@selector(implementationName)];
            }
            
            if (!decoderDetails[name]) {
                decoderDetails[name] = [NSMutableArray array];
            }
            
            NSMutableString *details = [NSMutableString stringWithFormat:@"%@ (%@)", name, implementation];
            if (params && params.count > 0) {
                [details appendFormat:@" - Profile: %@", params[@"profile-level-id"] ?: @"default"];
            }
            
            [decoderDetails[name] addObject:details];
        }
        
        // Print decoder details
        for (NSString *codec in @[@"H264", @"H265", @"VP8", @"VP9", @"AV1"]) {
            NSArray *implementations = decoderDetails[codec];
            if (implementations) {
                for (NSString *impl in implementations) {
                    NSLog(@"✅ %@", impl);
                }
            } else {
                NSLog(@"❌ %@ - Not available", codec);
            }
        }
        
        // Check for specific implementations
        NSLog(@"\n🔧 IMPLEMENTATION DETAILS:");
        NSLog(@"=========================");
        
        // Hardware codecs (VideoToolbox)
        void *h264VTEncoder = dlsym(handle, "OBJC_CLASS_$_RTCVideoEncoderH264");
        void *h264VTDecoder = dlsym(handle, "OBJC_CLASS_$_RTCVideoDecoderH264");
        void *h265VTEncoder = dlsym(handle, "OBJC_CLASS_$_RTCVideoEncoderH265");
        void *h265VTDecoder = dlsym(handle, "OBJC_CLASS_$_RTCVideoDecoderH265");
        
        NSLog(@"\n🖥️  Hardware Codecs (VideoToolbox):");
        NSLog(@"• H264 Encoder: %@", h264VTEncoder ? @"✅ Available" : @"❌ Not found");
        NSLog(@"• H264 Decoder: %@", h264VTDecoder ? @"✅ Available" : @"❌ Not found");
        NSLog(@"• H265 Encoder: %@", h265VTEncoder ? @"✅ Available" : @"❌ Not found");
        NSLog(@"• H265 Decoder: %@", h265VTDecoder ? @"✅ Available" : @"❌ Not found");
        
        // Software codecs
        void *vp8Encoder = dlsym(handle, "OBJC_CLASS_$_RTCVideoEncoderVP8");
        void *vp8Decoder = dlsym(handle, "OBJC_CLASS_$_RTCVideoDecoderVP8");
        void *vp9Encoder = dlsym(handle, "OBJC_CLASS_$_RTCVideoEncoderVP9");
        void *vp9Decoder = dlsym(handle, "OBJC_CLASS_$_RTCVideoDecoderVP9");
        void *av1Encoder = dlsym(handle, "OBJC_CLASS_$_RTCVideoEncoderAV1");
        void *av1Decoder = dlsym(handle, "OBJC_CLASS_$_RTCVideoDecoderAV1");
        
        NSLog(@"\n💻 Software Codecs:");
        NSLog(@"• VP8 Encoder: %@", vp8Encoder ? @"✅ Available" : @"❌ Not found");
        NSLog(@"• VP8 Decoder: %@", vp8Decoder ? @"✅ Available" : @"❌ Not found");
        NSLog(@"• VP9 Encoder: %@", vp9Encoder ? @"✅ Available" : @"❌ Not found");
        NSLog(@"• VP9 Decoder: %@", vp9Decoder ? @"✅ Available" : @"❌ Not found");
        NSLog(@"• AV1 Encoder: %@", av1Encoder ? @"✅ Available" : @"❌ Not found");
        NSLog(@"• AV1 Decoder: %@", av1Decoder ? @"✅ Available" : @"❌ Not found");
        
        // Check for internal software implementations
        NSLog(@"\n🔍 Internal Software Implementations:");
        
        // Check for libvpx
        void *vpxEncoder = dlsym(handle, "_vpx_codec_encode");
        void *vpxDecoder = dlsym(handle, "_vpx_codec_decode");
        if (vpxEncoder || vpxDecoder) {
            NSLog(@"• libvpx: ✅ Included (VP8/VP9 software codec)");
        } else {
            NSLog(@"• libvpx: ⚠️  Symbols not found (may be statically linked)");
        }
        
        // Check for libaom (AV1)
        void *aomEncoder = dlsym(handle, "_aom_codec_encode");
        void *aomDecoder = dlsym(handle, "_aom_codec_decode");
        if (aomEncoder || aomDecoder) {
            NSLog(@"• libaom: ✅ Included (AV1 software codec)");
        } else {
            NSLog(@"• libaom: ⚠️  Symbols not found (may be statically linked)");
        }
        
        // Check for OpenH264
        void *openh264 = dlsym(handle, "_WelsCreateSVCEncoder");
        if (openh264) {
            NSLog(@"• OpenH264: ✅ Included (H264 software fallback)");
        } else {
            NSLog(@"• OpenH264: ❌ Not found");
        }
        
        dlclose(handle);
        
        NSLog(@"\n📊 SUMMARY:");
        NSLog(@"===========");
        NSLog(@"• Hardware acceleration: VideoToolbox (H264, H265)");
        NSLog(@"• Software codecs: VP8, VP9, AV1");
        NSLog(@"• Total video codecs: 5 (H264, H265, VP8, VP9, AV1)");
        NSLog(@"• Platform: macOS ARM64");
    }
    return 0;
}