# WebRTC Binary Size Optimizations

This document details all size optimizations applied to reduce the WebRTC binary size from ~416MB to a target of ~200-250MB.

## Compiler & Linker Optimizations

### Link-Time Optimization (LTO)
- `use_lto=true` - Enables Link-Time Optimization
- `use_thin_lto=true` - Uses Thin LTO for faster builds
- **Expected savings**: 15-20%

### Aggressive Compiler Flags
- `-Os` - Optimize for size rather than speed
- `-ffunction-sections` - Place each function in its own section
- `-fdata-sections` - Place each data item in its own section
- `-Wl,-dead_strip` - Remove unused code sections (macOS equivalent of --gc-sections)
- **Expected savings**: 5-10%

### Symbol Stripping
- `symbol_level=0` - No debug symbols
- `enable_stripping=true` - Strip symbols from binary
- `remove_webcore_debug_symbols=true` - Remove WebCore debug symbols
- **Expected savings**: 5-10%

## Feature Removal

### Legacy API Removal
- `rtc_enable_legacy_api_video_quality_observer=false` - Remove deprecated video quality API
- `rtc_use_legacy_modules_directory=false` - Use modern module structure
- **Expected savings**: 2-5MB

### Debug & Development Features
- `rtc_include_tests=false` - Don't build tests
- `rtc_build_examples=false` - Don't build examples
- `rtc_build_tools=false` - Don't build tools
- `rtc_disable_trace_events=true` - Disable trace events
- `rtc_disable_metrics=true` - Disable metrics collection
- **Expected savings**: 5-10MB

### Platform Features
- `rtc_use_x11=false` - No X11 support (not needed on macOS)
- `rtc_use_pipewire=false` - No PipeWire support
- `rtc_use_gtk=false` - No GTK support
- **Expected savings**: 2-5MB

## Codec Optimization

### Audio Codecs Disabled by Default
- G.722 (`ENABLE_G722=false`) - Saves ~5MB
- iLBC (`ENABLE_ILBC=false`) - Saves ~5MB
- iSAC (`ENABLE_ISAC=false`) - Saves ~5MB
- **Total audio savings**: ~15MB

### System Libraries
- System Opus (`USE_SYSTEM_OPUS=true`) - Saves ~8-10MB
- System SSL (`USE_SYSTEM_SSL=true`) - Uses macOS native SSL

### Optional Video Codec Removal
For maximum size reduction, consider disabling:
- AV1 (`ENABLE_AV1=false`) - Saves ~80-100MB
- VP9 (`ENABLE_VP9=false`) - Saves ~30-40MB
- VP8 (not yet configurable) - Would save ~20-30MB

## Build System Optimizations

- `is_component_build=false` - Static linking for better optimization
- `use_clang_lld=true` - Use LLVM linker
- `clang_use_chrome_plugins=false` - Skip Chrome-specific plugins
- `enable_dead_code_stripping=true` - Remove unreachable code
- `optimize_for_size=true` - Global size optimization flag

## Size Comparison

### Before Optimizations
- Uncompressed: ~416MB
- Compressed: ~115MB

### After Optimizations (with all codecs)
- Uncompressed: ~250-300MB
- Compressed: ~70-85MB

### Maximum Reduction (without AV1/VP9)
- Uncompressed: ~150-200MB
- Compressed: ~40-55MB

## Verification

After building, check binary size:
```bash
./scripts/check_binary_size.sh
```

Verify optimizations applied:
```bash
# Check for system Opus usage
otool -L output/WebRTC.xcframework/macos-arm64/WebRTC.framework/WebRTC | grep opus

# Check symbol stripping
nm -a output/WebRTC.xcframework/macos-arm64/WebRTC.framework/WebRTC | wc -l

# Check section sizes
size -m output/WebRTC.xcframework/macos-arm64/WebRTC.framework/WebRTC
```

## Trade-offs

1. **Performance**: `-Os` may slightly reduce performance vs `-O2`
2. **Debugging**: No symbols makes debugging harder
3. **Dependencies**: System Opus requires Homebrew installation
4. **Features**: Some legacy APIs removed

These trade-offs are generally acceptable for production builds where binary size is a priority.