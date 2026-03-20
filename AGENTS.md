# Termux Generator - Project Context

## Project Overview

**Termux Generator** is a build automation tool for creating customized Termux applications from source with modified package names. It enables:

- Running multiple Termux instances side-by-side on the same device
- Creating specialized Termux builds with pre-installed packages
- Customizing Termux behavior through patches
- Building custom bootstraps via GitHub Actions CI/CD

**Repository:** Fork of [robertkirkman/termux-generator](https://github.com/robertkirkman/termux-generator)

### Key Technologies
| Technology | Purpose |
|------------|---------|
| Bash | Build automation and orchestration |
| Docker | Containerized build environment (`ghcr.io/termux/package-builder`) |
| Gradle/Android SDK | Android APK compilation |
| Git | Source repository management and patching |
| GitHub Actions | CI/CD workflow automation |
| patch | Applying diffs to cloned repositories |

### Supported Build Types
| Type | Description | Features |
|------|-------------|----------|
| `f-droid` (default) | F-Droid variant | Full plugin support, bootstrap second stage, SSH server option |
| `play-store` | Google Play Store variant | Limited plugin support, no bootstrap second stage |

---

## Project Structure

```
termux-generator-fork/
├── build-termux.sh              # Main entry point - argument parsing, orchestration
├── README.md                    # User documentation
├── AGENTS.md                    # This file - AI agent context
├── .gitignore
├── .github/
│   └── workflows/
│       └── build-bootstrap.yml  # GitHub Actions: Custom bootstrap builder
├── scripts/
│   ├── termux_generator_steps.sh   # Build step functions (download, patch, build, move)
│   └── termux_generator_utils.sh   # Utility functions (patching, name replacement, migration)
└── f-droid-patches/
    ├── app-patches/             # Patches applied to Termux app repositories
    │   ├── auto-hide-extra-keys.patch              # Hide extra keys when hardware keyboard connected
    │   ├── disable-termux-x11-signature-check.patch # Remove X11 signature verification
    │   ├── increase-gradle-memory.patch            # Increase JVM heap to 8GB
    │   ├── local-bootstraps.patch                  # Load bootstraps from assets (not native lib)
    │   ├── local-maven.patch                       # Use mavenLocal for dependencies
    │   ├── local-termux-am-library.patch           # Use local termux-am-library
    │   ├── local-termux-gui.patch                  # Disable proto generation requirement
    │   └── multi-window.patch                      # Android multi-window support
    └── bootstrap-patches/       # Patches applied to termux-packages repository
        ├── build-bootstraps.patch                  # Enhanced bootstrap building with 7zip
        ├── build-package-support-subpackages.patch # Support subpackage discovery
        ├── builder-name-change.patch               # Docker container rename, CI optimizations
        ├── name-change-helper.patch                # MOTD customization, package name replacement
        ├── opengl-actual-package.patch             # Fix opengl metapackage dependencies
        └── subversion-apr.patch                    # Fix subversion APR include path
```

---

## Build Process Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                      build-termux.sh                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  1. CLEAN (unless --dirty)                                      │
│     ├── clean_docker(): Kill/remove containers, remove images   │
│     └── clean_artifacts(): rm -rf termux* *.apk *.deb *.zip     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. DOWNLOAD                                                    │
│     F-Droid type:                                               │
│       - termux/termux-packages                                  │
│       - termux/termux-app, termux-tasker, termux-float, etc.    │
│       - termux/termux-am-library (moved into termux-app)        │
│     Play-Store type:                                            │
│       - termux-play-store/termux-packages                       │
│       - termux-play-store/termux-apps                           │
│     Both:                                                       │
│       - termux/termux-x11 (recursive)                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. PLUGIN (if --plugin specified)                              │
│     ├── build_plugin(): ./gradlew build                         │
│     └── install_plugin(): Copy to assets, apply plugin patches  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. PATCH BOOTSTRAPS                                            │
│     Order matters:                                              │
│     1. replace_termux_name() - Replace com.termux in all files  │
│     2. apply_patches() - Apply bootstrap-patches/               │
│     3. SSH server setup (if --enable-ssh-server)                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. PATCH APPS                                                  │
│     Order matters (reverse of bootstraps):                      │
│     1. apply_patches() - Apply app-patches/                     │
│     2. replace_termux_name() - Replace com.termux in all files  │
│     3. migrate_termux_folder_tree() - Move Java packages        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  6. BUILD X11 (unless --disable-x11)                           │
│     ├── ./gradlew assembleDebug                                 │
│     └── ./build_termux_package → termux-x11-nightly_all.deb     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  7. BUILD BOOTSTRAPS (unless --disable-bootstrap)              │
│     F-Droid: scripts/run-docker.sh scripts/build-bootstraps.sh  │
│     Play-Store: scripts/run-docker.sh scripts/generate-bootstraps.sh │
│     Output: bootstrap-{arch}.zip files                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  8. BUILD APPS (unless --disable-terminal)                     │
│     F-Droid:                                                    │
│       1. termux-app: ./gradlew publishReleasePublicationToMavenLocal │
│       2. All apps: ./gradlew assembleDebug (per app)            │
│     Play-Store:                                                 │
│       ./gradlew assembleDebug (root level)                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  9. MOVE ARTIFACTS                                              │
│     ├── move_bootstraps(): Move .zip to assets/ or root         │
│     └── move_apks(): Move .apk files to root                    │
│     Naming: {package_name}-{type}-{original_name}.apk           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Command Line Reference

### Usage
```bash
./build-termux.sh [options]
```

### Options

| Option | Argument | Default | Description |
|--------|----------|---------|-------------|
| `-n, --name` | APP_NAME | `com.termux` | Custom package name |
| `-t, --type` | APP_TYPE | `f-droid` | Build type: `f-droid` or `play-store` |
| `-a, --add` | PKG_LIST | `xkeyboard-config` | Comma-separated additional packages |
| `--architectures` | ARCH_LIST | `aarch64,x86_64,arm,i686` | Comma-separated architectures |
| `-p, --plugin` | PLUGIN | (none) | Plugin name from plugins/ folder |
| `-d, --dirty` | - | (disabled) | Skip cleanup, reuse previous artifacts |
| `-h, --help` | - | - | Show help message |

### Feature Flags (all default to enabled)

| Flag | Affects | Notes |
|------|---------|-------|
| `--disable-bootstrap-second-stage` | f-droid only | Prevents automatic bootstrap second stage |
| `--enable-ssh-server` | f-droid only | Bundles SSH server (requires bootstrap second stage) |
| `--disable-bootstrap` | both | Skip building bootstrap archives |
| `--disable-terminal` | both | Skip building main Termux app |
| `--disable-x11` | both | Skip building Termux:X11 |
| `--disable-tasker` | f-droid only | Skip Termux:Tasker |
| `--disable-float` | f-droid only | Skip Termux:Float |
| `--disable-widget` | f-droid only | Skip Termux:Widget |
| `--disable-api` | f-droid only | Skip Termux:API |
| `--disable-boot` | f-droid only | Skip Termux:Boot |
| `--disable-styling` | f-droid only | Skip Termux:Styling |
| `--disable-gui` | f-droid only | Skip Termux:GUI |

### Example Commands

```bash
# Minimal custom build
./build-termux.sh --name com.myapp.termux

# Full development environment
./build-termux.sh --name com.dev.termux \
    --add clang,cmake,make,git,python,nodejs-lts,openjdk-17 \
    --architectures aarch64

# Headless device setup with SSH
./build-termux.sh --name com.headless.termux --enable-ssh-server

# Bootstrap-only (no APK) for CI
./build-termux.sh --name com.bootstrap.termux \
    --disable-terminal --disable-tasker --disable-float \
    --disable-widget --disable-api --disable-boot \
    --disable-styling --disable-gui --disable-x11

# Troubleshooting with dirty build
./build-termux.sh --name com.test.termux --dirty
```

---

## Package Name Validation

Package names are validated in `check_names()` with these restrictions:

### Forbidden Characters
- Underscores (`_`)
- Dashes (`-`)

### Forbidden Patterns
| Pattern | Reason |
|---------|--------|
| `package`, `package.*`, `*.package`, `*.package.*` | Reserved Java keyword |
| `in`, `in.*`, `*.in`, `*.in.*` | Reserved Java keyword |
| `is`, `is.*`, `*.is`, `*.is.*` | Reserved Java keyword |
| `as`, `as.*`, `*.as`, `*.as.*` | Reserved Java keyword |

### Termux-specific Restrictions
- Cannot contain `com.termux` as substring (unless exactly `com.termux`)
- Example: `com.test.termux` ✓ | `com.termux.test` ✗

### termux-x11-nightly Restriction
- Cannot be added via `--add` (it's precompiled and auto-included)

---

## Patch Documentation

### App Patches (f-droid-patches/app-patches/)

| Patch | Purpose | Affected Files |
|-------|---------|----------------|
| `auto-hide-extra-keys.patch` | Hide extra keys toolbar when hardware keyboard detected | TermuxActivity.java, preferences, strings |
| `disable-termux-x11-signature-check.patch` | Remove X11 signature verification for custom builds | Loader.java |
| `increase-gradle-memory.patch` | Increase Gradle JVM heap from 2GB to 8GB | gradle.properties |
| `local-bootstraps.patch` | Load bootstraps from APK assets instead of native library | build.gradle, TermuxInstaller.java |
| `local-maven.patch` | Use mavenLocal for termux-shared/terminal-view dependencies | Multiple build.gradle files |
| `local-termux-am-library.patch` | Include termux-am-library as local project | settings.gradle, termux-shared/build.gradle |
| `local-termux-gui.patch` | Disable proto generation requirement for non-CI builds | termux-gui/app/build.gradle |
| `multi-window.patch` | Android N+ multi-window support with session management | Multiple Java files, layouts |

### Bootstrap Patches (f-droid-patches/bootstrap-patches/)

| Patch | Purpose | Affected Files |
|-------|---------|----------------|
| `build-bootstraps.patch` | Enhanced bootstrap building with 7zip compression, pull_package function | build-bootstraps.sh, termux-bootstrap-second-stage.sh |
| `build-package-support-subpackages.patch` | Support building subpackages by name | build-package.sh |
| `builder-name-change.patch` | Rename Docker container, CI space optimization | run-docker.sh, free-space.sh |
| `name-change-helper.patch` | Custom MOTD, name replacement for termux-tools/termux-am | termux-tools/build.sh, termux-am/build.sh |
| `opengl-actual-package.patch` | Fix opengl metapackage build dependency | packages/opengl/build.sh |
| `subversion-apr.patch` | Fix subversion APR include path | packages/subversion/build.sh |

---

## GitHub Actions Workflow

### build-bootstrap.yml

**Trigger:** Manual (`workflow_dispatch`)

**Inputs:**
| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `package_name` | string | `com.agentclaw` | Custom package name |
| `minimal_bootstrap` | boolean | `false` | Use minimal package set |
| `ssh_server` | boolean | `false` | Bundle SSH server |

**Environment:**
| Variable | Value |
|----------|-------|
| `ARCHITECTURE` | `aarch64` |
| `TERMUX_TYPE` | `f-droid` |
| `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` | `true` | Required for Node.js 24 actions |
| `FULL_PACKAGES` | git,curl,wget,nano,tmux,htop,jq,ca-certificates,openssl-tool,openssh,screen,pacman,nodejs-lts,python,build-essential,clang,cmake,make,autoconf,automake,libtool,pkg-config,gradle,openjdk-17,binutils,gdb,unzip,p7zip,sqlite |
| `MINIMAL_PACKAGES` | git,curl,wget,nano,tmux,htop,jq,ca-certificates,openssl-tool,openssh,screen,pacman |

**Outputs:**
- Artifact: `bootstrap-{package_name}-{type}.zip`
- Release: `v{run_number}-{package_name}`

**Note:** Node.js 20 actions are deprecated as of June 2nd, 2026. The workflow uses `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true` to opt into Node.js 24.

---

## Utility Functions Reference

### scripts/termux_generator_utils.sh

| Function | Parameters | Purpose |
|----------|------------|---------|
| `portable_sed_i` | sed arguments | Cross-platform sed -i (macOS/Linux compatible) |
| `apply_patches` | srcdir, targetdir | Apply all patches from directory to target |
| `replace_termux_name` | targetdir, replacement_name | Replace `com.termux` with custom name in text files |
| `migrate_termux_folder` | path, replacement_name | Move `com/termux/` to new package path |
| `migrate_termux_folder_tree` | targetdir, replacement_name | Recursively migrate all Java package directories |

### scripts/termux_generator_steps.sh

| Function | Purpose |
|----------|---------|
| `check_names` | Validate package name |
| `clean_docker` | Kill/remove Docker containers and images |
| `clean_artifacts` | Remove build artifacts |
| `download` | Clone all required repositories |
| `build_plugin` | Build plugin with Gradle |
| `install_plugin` | Install plugin and apply its patches |
| `patch_bootstraps` | Apply bootstrap patches, setup SSH |
| `patch_apps` | Apply app patches, migrate package structure |
| `build_termux_x11` | Build termux-x11 package |
| `move_termux_x11_deb` | Move termux-x11 .deb to output |
| `build_bootstraps` | Build bootstrap archives in Docker |
| `move_bootstraps` | Move bootstrap .zip files |
| `build_apps` | Build all APKs with Gradle |
| `move_apks` | Move APK files to output |

---

## Development Conventions

### Shell Script Style
```bash
# Always use strict mode
set -e -u -o pipefail

# Directory navigation
pushd "directory"
# ... work ...
popd

# Conditionals (Bash-specific)
[[ "$var" == "value" ]]

# Command substitution
result=$(command)

# Always quote variables
"$variable"
"${array[@]}"
```

### Patch Application Order
```
Bootstraps: replace_name → apply_patches
Apps:       apply_patches → replace_name → migrate_folders
```

**Why the difference?**
- Bootstraps need name replacement first so patches like `name-change-helper.patch` can reference the new name
- Apps have more `com.termux` references, so patches apply to original code first, then names are replaced

### Docker Configuration
- Container: `termux-generator-package-builder`
- Images: `ghcr.io/termux/package-builder` (f-droid), `ghcr.io/termux-play-store/package-builder`
- Security: `--privileged` with `seccomp=unconfined` (required for build operations)

---

## Output Files

### After Successful Build

| File Pattern | Example | Description |
|--------------|---------|-------------|
| `{name}-{type}-termux-app_*.apk` | `com.myapp-f-droid-termux-app_apt-android-7-debug_universal.apk` | Main Termux app |
| `{name}-{type}-termux-x11_*.apk` | `com.myapp-f-droid-termux-x11_*.apk` | Termux:X11 app |
| `{name}-{type}-termux-tasker_*.apk` | `com.myapp-f-droid-termux-tasker_*.apk` | Termux:Tasker |
| `{name}-{type}-termux-float_*.apk` | - | Termux:Float |
| `{name}-{type}-termux-widget_*.apk` | - | Termux:Widget |
| `{name}-{type}-termux-api_*.apk` | - | Termux:API |
| `{name}-{type}-termux-boot_*.apk` | - | Termux:Boot |
| `{name}-{type}-termux-styling_*.apk` | - | Termux:Styling |
| `{name}-{type}-termux-gui_*.apk` | - | Termux:GUI |
| `{name}-{type}-bootstrap-{arch}.zip` | `com.myapp-f-droid-bootstrap-aarch64.zip` | Bootstrap archive (if --disable-terminal) |

---

## Important Notes

### Build Environment Requirements
| Requirement | Local Build | GitHub Actions |
|-------------|-------------|----------------|
| Docker | ✓ Required | ✓ Pre-installed |
| Android SDK | ✓ Required | ✓ Pre-installed |
| OpenJDK 17 | ✓ Required | ✓ Pre-installed |
| git, patch, bash | ✓ Required | ✓ Pre-installed |
| ANDROID_SDK_ROOT | ✓ Must be set | ✓ Pre-configured |

### Build Time Estimates
| Scenario | Estimated Time |
|----------|----------------|
| Minimal (no extra packages) | 30-60 minutes |
| Typical (clang, git, python) | 2-3 hours |
| Full development environment | 3-4 hours |

### SSH Server Feature
- **Requires:** `--type f-droid` (play-store doesn't support bootstrap second stage)
- **Default password:** `changeme`
- **Startup:** Launches on TermuxActivity start
- **Headless setup:** Use `adb shell am start -n {package}/.app.TermuxActivity`

### Troubleshooting Tips
1. **Build fails:** Try `--dirty` to reuse artifacts and isolate the issue
2. **Docker issues:** Run `docker system prune -a` to clean up
3. **Out of disk space:** CI runs `scripts/free-space.sh` automatically
4. **Patch conflicts:** Patches are based on specific commit hashes; upstream changes may require rebase

---

## Related Resources

- [Termux Wiki](https://wiki.termux.com/)
- [Termux GitHub](https://github.com/termux)
- [Termux Packages](https://github.com/termux/termux-packages)
- [Docker Hub - termux/package-builder](https://github.com/termux/termux-packages/pkgs/container/package-builder)