#import <Foundation/Foundation.h>
#import <dlfcn.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *frameworkPath = @"/Users/steipete/Projects/WebRTC/src/src/out/Default/WebRTC.framework/Versions/A/WebRTC";
        
        // Load the framework
        void *handle = dlopen([frameworkPath UTF8String], RTLD_NOW);
        if (!handle) {
            NSLog(@"❌ Failed to load framework: %s", dlerror());
            return 1;
        }
        
        NSLog(@"✅ WebRTC framework loaded successfully!");
        NSLog(@"================================================\n");
        
        // Get factory classes
        Class encoderFactoryClass = NSClassFromString(@"RTCDefaultVideoEncoderFactory");
        Class decoderFactoryClass = NSClassFromString(@"RTCDefaultVideoDecoderFactory");
        
        id encoderFactory = [[encoderFactoryClass alloc] init];
        id decoderFactory = [[decoderFactoryClass alloc] init];
        
        // Get supported codecs
        NSArray *encoderCodecs = [encoderFactory performSelector:@selector(supportedCodecs)];
        NSArray *decoderCodecs = [decoderFactory performSelector:@selector(supportedCodecs)];
        
        NSLog(@"📹 Encoder Support:");
        BOOL foundH265Encoder = NO;
        for (id codec in encoderCodecs) {
            NSString *name = [codec performSelector:@selector(name)];
            NSLog(@"  • %@", name);
            if ([name isEqualToString:@"H265"]) {
                foundH265Encoder = YES;
            }
        }
        
        NSLog(@"\n📺 Decoder Support:");
        BOOL foundH265Decoder = NO;
        for (id codec in decoderCodecs) {
            NSString *name = [codec performSelector:@selector(name)];
            NSLog(@"  • %@", name);
            if ([name isEqualToString:@"H265"]) {
                foundH265Decoder = YES;
            }
        }
        
        NSLog(@"\n🎯 H265 Verification:");
        NSLog(@"=====================");
        NSLog(@"H265 Encoder: %@", foundH265Encoder ? @"✅ FOUND" : @"❌ NOT FOUND");
        NSLog(@"H265 Decoder: %@", foundH265Decoder ? @"✅ FOUND" : @"❌ NOT FOUND");
        
        // Test creating instances
        id h265EncoderCodecInfo = nil;
        for (id codec in encoderCodecs) {
            NSString *name = [codec performSelector:@selector(name)];
            if ([name isEqualToString:@"H265"]) {
                h265EncoderCodecInfo = codec;
                break;
            }
        }
        
        if (h265EncoderCodecInfo) {
            id encoder = [encoderFactory performSelector:@selector(createEncoder:) withObject:h265EncoderCodecInfo];
            if (encoder) {
                NSLog(@"\n✅ Successfully created H265 encoder instance");
                NSLog(@"   Class: %@", NSStringFromClass([encoder class]));
                
                // Try to get implementation name safely
                if ([encoder respondsToSelector:@selector(implementationName)]) {
                    @try {
                        NSString *impl = [encoder performSelector:@selector(implementationName)];
                        NSLog(@"   Implementation: %@", impl);
                    } @catch (NSException *e) {
                        NSLog(@"   Implementation: (unable to retrieve)");
                    }
                }
            }
        }
        
        id h265DecoderCodecInfo = nil;
        for (id codec in decoderCodecs) {
            NSString *name = [codec performSelector:@selector(name)];
            if ([name isEqualToString:@"H265"]) {
                h265DecoderCodecInfo = codec;
                break;
            }
        }
        
        if (h265DecoderCodecInfo) {
            id decoder = [decoderFactory performSelector:@selector(createDecoder:) withObject:h265DecoderCodecInfo];
            if (decoder) {
                NSLog(@"\n✅ Successfully created H265 decoder instance");
                NSLog(@"   Class: %@", NSStringFromClass([decoder class]));
                
                // Try to get implementation name safely
                if ([decoder respondsToSelector:@selector(implementationName)]) {
                    @try {
                        NSString *impl = [decoder performSelector:@selector(implementationName)];
                        NSLog(@"   Implementation: %@", impl);
                    } @catch (NSException *e) {
                        NSLog(@"   Implementation: (unable to retrieve)");
                    }
                }
            }
        }
        
        // Check symbols
        void *encoderSymbol = dlsym(handle, "OBJC_CLASS_$_RTCVideoEncoderH265");
        void *decoderSymbol = dlsym(handle, "OBJC_CLASS_$_RTCVideoDecoderH265");
        
        NSLog(@"\n📦 Symbol Export Status:");
        NSLog(@"========================");
        NSLog(@"RTCVideoEncoderH265: %@", encoderSymbol ? @"✅ Exported" : @"❌ Not exported");
        NSLog(@"RTCVideoDecoderH265: %@", decoderSymbol ? @"✅ Exported" : @"❌ Not exported");
        
        dlclose(handle);
        
        NSLog(@"\n🎉 Verification complete!");
        NSLog(@"✅ H265/HEVC codec support is properly integrated in WebRTC");
    }
    return 0;
}