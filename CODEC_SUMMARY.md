# WebRTC Framework Codec Summary

## Video Codecs Included

### 🎥 Video Encoders

1. **H.264 (2 profiles)** - Hardware Accelerated
   - Implementation: VideoToolbox (macOS native)
   - Profile 1: Constrained High (640c1f)
   - Profile 2: Constrained Baseline (42e01f)
   - Hardware acceleration on Apple Silicon and Intel Macs

2. **H.265/HEVC** - Hardware Accelerated
   - Implementation: VideoToolbox (macOS native)
   - Profiles: Main, Main10
   - Hardware acceleration on Apple Silicon and Intel Macs with T2 chip
   - ✅ **NEW - Added in this build**

3. **VP8** - Software
   - Implementation: libvpx (built-in)
   - Cross-platform software encoder
   - Good compatibility with older devices

4. **VP9** - Software
   - Implementation: libvpx (built-in)
   - Cross-platform software encoder
   - Better compression than VP8
   - Supports SVC (Scalable Video Coding)

5. **AV1** - Software (Encoder NOT included)
   - ❌ Encoder not available in this build
   - Would require libaom encoder (not enabled)

### 📺 Video Decoders

1. **H.264 (2 profiles)** - Hardware Accelerated
   - Implementation: VideoToolbox (macOS native)
   - Profile 1: Constrained High (640c1f)
   - Profile 2: Constrained Baseline (42e01f)
   - Hardware acceleration on all modern Macs

2. **H.265/HEVC** - Hardware Accelerated
   - Implementation: VideoToolbox (macOS native)
   - Profiles: Main, Main10
   - Hardware acceleration on Apple Silicon and Intel Macs with T2 chip
   - ✅ **NEW - Added in this build**

3. **VP8** - Software
   - Implementation: libvpx (built-in)
   - Cross-platform software decoder

4. **VP9** - Software
   - Implementation: libvpx (built-in)
   - Cross-platform software decoder

5. **AV1** - Software
   - Implementation: dav1d (built-in)
   - High-performance software decoder
   - ✅ Decoder is included

## Implementation Details

### Hardware Codecs (VideoToolbox)
- **H.264**: Uses Apple's VideoToolbox framework for hardware encoding/decoding
- **H.265**: Uses Apple's VideoToolbox framework for hardware encoding/decoding
- Benefits: Low CPU usage, low power consumption, low latency
- Availability: All codecs use hardware when available, software fallback otherwise

### Software Codecs
- **VP8/VP9**: Uses libvpx library (statically linked)
- **AV1**: Uses dav1d for decoding (statically linked)
- Benefits: Cross-platform compatibility, consistent behavior
- Drawbacks: Higher CPU usage compared to hardware codecs

## Symbol Visibility

Due to the way WebRTC is built, most codec symbols are local (not exported) except:
- ✅ RTCVideoEncoderH265 (exported globally)
- ✅ RTCVideoDecoderH265 (exported globally)

Other codecs are accessible through the factory classes:
- RTCDefaultVideoEncoderFactory
- RTCDefaultVideoDecoderFactory

## Performance Characteristics

### Best Performance (Hardware):
1. H.265 - Newest, best compression, hardware accelerated
2. H.264 - Widely supported, hardware accelerated

### Good Performance (Software):
3. VP9 - Better compression than VP8
4. VP8 - Good compatibility
5. AV1 - Best compression but highest CPU usage (decode only)

## Recommended Usage

- **For Apple devices**: Use H.265 (best) or H.264
- **For cross-platform**: Use VP9 or VP8
- **For future-proofing**: H.265 offers the best balance of quality and performance

## Build Configuration

The framework was built with:
- `rtc_use_h264=true` - H.264 support enabled
- `rtc_use_h265=true` - H.265 support enabled
- `proprietary_codecs=true` - Allows H.264/H.265
- `rtc_include_dav1d_in_internal_decoder_factory=true` - AV1 decoder included
- `enable_libaom=false` - AV1 encoder not included