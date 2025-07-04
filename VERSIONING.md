# WebRTC Versioning Information

## Current Build

This WebRTC framework was built from:
- **Branch**: main (latest development)
- **Commit**: 6154b71a15
- **Date**: 2025-07-04

## Chromium Milestone Mapping

WebRTC follows Chromium's release schedule. Here's how to interpret versions:

- **main branch**: Latest development (ahead of stable)
- **M139**: Current Chromium Beta/Canary milestone
- **M138**: Current Chromium Stable milestone

## Branch Strategy

### For Stable Releases (Recommended for Production)
To build from a specific milestone branch:
```bash
# In fetch_webrtc.sh, after gclient sync, checkout the milestone branch:
cd src
git checkout branch-heads/6680  # For M139
gclient sync
```

### For Latest Features (Current Build)
Building from `main` gives you:
- Latest codec improvements
- Newest features
- Potential instability
- Ahead of stable releases by ~6-12 weeks

## Version Naming

We use "M139" as our version tag because:
1. The main branch is typically ahead of or at the current beta milestone
2. It indicates approximate feature parity with Chromium M139
3. It's clearer than using commit hashes

## Finding Milestone Branches

To find the correct branch for a milestone:
```bash
# List available milestone branches
git branch -r | grep branch-heads | sort -V | tail -20

# Common milestone branches:
# branch-heads/6680  # M139 (Beta)
# branch-heads/6613  # M138 (Stable)
# branch-heads/6544  # M137
```

## Recommendation

For production use, consider rebuilding from a stable milestone branch:
1. Modify `scripts/fetch_webrtc.sh` to checkout a specific branch
2. Rebuild with `./build_all.sh`
3. Tag release with actual milestone (e.g., "M138-stable")