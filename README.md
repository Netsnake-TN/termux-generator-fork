# Termux Generator

Build customized Termux applications from source with modified package names, pre-installed packages, and custom configurations.

## Why Termux Generator?

| Problem | Solution |
|---------|----------|
| Can't run multiple Termux instances | Build with unique package names |
| Need packages pre-installed | Bootstrap includes your packages |
| Want custom Termux behavior | Apply patches during build |
| No local build environment | Use GitHub Actions CI/CD |

## Quick Start

### GitHub Actions (Recommended)

1. Fork this repository
2. Go to **Actions** → **Build Custom Bootstrap** → **Run workflow**
3. Enter your package name (e.g., `com.myapp.termux`)
4. Download artifacts when build completes

### Local Build

```bash
# Clone
git clone https://github.com/Netsnake-TN/termux-generator-fork.git
cd termux-generator-fork

# Build with custom name
./build-termux.sh --name com.myapp.termux

# Build with pre-installed packages
./build-termux.sh --name com.dev.termux \
    --add clang,cmake,git,python,nodejs-lts \
    --architectures aarch64
```

## Requirements

| Requirement | Local Build | GitHub Actions |
|-------------|-------------|----------------|
| Docker | Required | Pre-installed |
| git, patch, bash | Required | Pre-installed |
| Android SDK | Required | Not needed |
| OpenJDK 17 | Required | Not needed |

## Command Reference

```bash
./build-termux.sh [options]
```

| Option | Default | Description |
|--------|---------|-------------|
| `-n, --name` | `com.termux` | Custom package name |
| `-t, --type` | `f-droid` | Build type (`f-droid` or `play-store`) |
| `-a, --add` | `xkeyboard-config` | Comma-separated packages to pre-install |
| `--architectures` | `aarch64,x86_64,arm,i686` | Target architectures |
| `--enable-ssh-server` | disabled | Bundle SSH server (f-droid only) |
| `-d, --dirty` | disabled | Skip cleanup for troubleshooting |

### Disable Flags

```bash
--disable-terminal    # Skip main Termux app
--disable-bootstrap   # Skip bootstrap archive
--disable-x11         # Skip Termux:X11
--disable-tasker      # Skip Termux:Tasker
--disable-float       # Skip Termux:Float
--disable-widget      # Skip Termux:Widget
--disable-api         # Skip Termux:API
--disable-boot        # Skip Termux:Boot
--disable-styling     # Skip Termux:Styling
--disable-gui         # Skip Termux:GUI
```

## Use Cases

### Multiple Termux Instances

```bash
# Build first instance
./build-termux.sh --name com.work.termux

# Build second instance  
./build-termux.sh --name com.personal.termux
```

### Headless Device Setup

```bash
# Build with SSH server
./build-termux.sh --name com.headless.termux --enable-ssh-server

# Install via ADB
adb install com.headless-f-droid-termux-app_*.apk
adb shell am start -n com.headless.termux/.app.TermuxActivity

# Connect (default password: changeme)
ssh -p 8022 user@device-ip
```

### Development Environment

```bash
./build-termux.sh --name com.dev.termux \
    --add clang,cmake,make,git,python,nodejs-lts,openjdk-17,gradle \
    --architectures aarch64
```

### GUI Desktop (XFCE)

```bash
./build-termux.sh --name com.desktop.termux \
    --add xfce4,xfce4-terminal,thunar,xfconf,xfwm4,xfdesktop \
    --architectures aarch64

# After install, launch with:
termux-x11 -xstartup xfce4-session &
```

## Package Name Rules

- No underscores (`_`) or dashes (`-`)
- Cannot contain `com.termux` as substring
- Cannot use Java keywords: `package`, `in`, `is`, `as`

**Valid:** `com.myapp.termux`, `org.custom.shell`

**Invalid:** `com.termux.test`, `com.my_app`, `com.my-app`

## Output Files

| Pattern | Description |
|---------|-------------|
| `{name}-{type}-termux-app_*.apk` | Main Termux app |
| `{name}-{type}-termux-x11_*.apk` | Termux:X11 |
| `{name}-{type}-termux-tasker_*.apk` | Termux:Tasker |
| `{name}-{type}-bootstrap-{arch}.zip` | Bootstrap archive |

## Build Times

| Configuration | Estimated Time |
|---------------|----------------|
| Minimal (no extra packages) | 30-60 minutes |
| Typical (clang, git, python) | 2-3 hours |
| Full development environment | 3-4 hours |

## Project Structure

```
termux-generator-fork/
├── build-termux.sh           # Main entry point
├── scripts/
│   ├── termux_generator_steps.sh  # Build steps
│   └── termux_generator_utils.sh  # Utilities
├── f-droid-patches/
│   ├── app-patches/          # Termux app patches
│   └── bootstrap-patches/    # Bootstrap patches
└── .github/workflows/
    └── build-bootstrap.yml   # CI/CD workflow
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Build fails | Try `--dirty` to reuse artifacts |
| Docker issues | Run `docker system prune -a` |
| Out of disk space | Remove old builds |
| Patch conflicts | May need rebase on upstream changes |

## Credits

Fork of [robertkirkman/termux-generator](https://github.com/robertkirkman/termux-generator)

Built on [Termux](https://termux.dev/) by Fredrik Fornwall and contributors.