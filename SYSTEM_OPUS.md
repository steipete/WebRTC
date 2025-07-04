# Using System Opus with WebRTC

This build is configured to use the system-provided Opus library instead of bundling WebRTC's internal copy. This reduces the binary size by approximately 5-10MB.

## Requirements

- macOS 14.0 (Sonoma) or later
- Opus library installed via Homebrew

## Installation

The build process expects Opus to be installed via Homebrew:

```bash
brew install opus
```

This installs Opus to `/opt/homebrew/opt/opus` on Apple Silicon Macs.

## Configuration

The build is configured with:
- `USE_SYSTEM_OPUS=true` in `build_config.sh`
- `rtc_build_opus=false` in the GN args to skip building WebRTC's bundled Opus
- Include and library paths pointing to the Homebrew installation

## Deployment Considerations

When using system Opus, the framework has a runtime dependency on the Opus library. This means:

1. **For Development**: Opus must be installed on development machines
2. **For Distribution**: You have two options:
   - Require users to install Opus (not recommended)
   - Bundle Opus.dylib with your application
   - Use install_name_tool to adjust the library paths

## Verifying System Opus Usage

After building, you can verify that the framework uses system Opus:

```bash
# Check library dependencies
otool -L output/WebRTC.xcframework/macos-arm64/WebRTC.framework/WebRTC | grep opus

# Should show something like:
# /opt/homebrew/opt/opus/lib/libopus.0.dylib
```

## Binary Size Impact

Using system Opus typically saves:
- Uncompressed: ~8-10MB
- Compressed: ~3-5MB

## Compatibility

System Opus is well-supported on macOS 14+ and provides the same API as the bundled version. The current Homebrew version (1.5.2) is fully compatible with WebRTC's requirements.