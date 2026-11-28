# Alibi

## Install

Alibi installs through [mise](https://mise.jdx.dev/) from its [GitHub releases](https://github.com/setdef/Alibi/releases). Each release has a build for each platform, and the build carries its own Ruby, so your computer needs none. Put this in a project's `mise.toml`, or in `~/.config/mise/config.toml` for every project, and run `mise install`:

```toml
[tools."github:setdef/Alibi"]
version = "latest"
strip_components = 1
bin_path = "."

[tools."github:setdef/Alibi".platforms]
macos-arm64 = { asset_pattern = "alibi-arm64-darwin.tar.gz" }
linux-x64 = { asset_pattern = "alibi-x86_64-linux.tar.gz" }
linux-arm64 = { asset_pattern = "alibi-aarch64-linux.tar.gz" }
windows-x64 = { asset_pattern = "alibi-x64-mingw-ucrt.zip" }
windows-arm64 = { asset_pattern = "alibi-aarch64-mingw-ucrt.zip" }
```

`mise exec -- alibi --version` then prints the installed version. `strip_components` and `bin_path` put the `alibi` program on your `PATH` and leave out the Ruby that comes in the build. Without them, mise puts that Ruby ahead of your own.

On Linux with [musl](https://musl.libc.org/), such as [Alpine](https://alpinelinux.org/), use the musl builds:

```toml
[tools."github:setdef/Alibi"]
version = "latest"
strip_components = 1
bin_path = "."

[tools."github:setdef/Alibi".platforms]
linux-x64 = { asset_pattern = "alibi-x86_64-linux-musl.tar.gz" }
linux-arm64 = { asset_pattern = "alibi-aarch64-linux-musl.tar.gz" }
```

| Platform | Runs on |
| --- | --- |
| `arm64-darwin` | macOS 14 or newer, on Apple silicon |
| `x86_64-linux`, `aarch64-linux` | Linux with glibc 2.39 or newer, such as Ubuntu 24.04 |
| `x86_64-linux-musl`, `aarch64-linux-musl` | Linux with musl |
| `x64-mingw-ucrt`, `aarch64-mingw-ucrt` | Windows 11, on x64 or ARM64 |
