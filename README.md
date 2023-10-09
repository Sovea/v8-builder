# V8 Builder
#### An automatic V8 monolith builder via Github Actions

![Build V8](https://github.com/truexpixells/v8-builder/workflows/Build%20V8/badge.svg?branch=master)

## Building info
**V8 is compiled as is**, without patches or changes of any kind.
The version used to compile is the most recent stable shown at https://omahaproxy.appspot.com (as described [here](https://v8.dev/docs/source-code#source-code-branches)).

V8 binaries are built for the following platforms (or not):
- Linux (armv7, arm64, x64, x86)
- Android (armv7, arm64, x64, x86)
- macOS (x64, arm64)
- Windows (x64, x86, arm64)

Headers are included!

## Releases
See [release](https://github.com/truexpixells/v8-builder/releases) for available versions to download.
