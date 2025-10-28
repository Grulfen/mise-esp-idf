# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a mise plugin for managing ESP-IDF (Espressif IoT Development Framework) installations. It's written in Lua using the mise/vfox plugin API.

## Plugin Architecture

The plugin follows the mise plugin lifecycle with four hook files in `hooks/`:

1. **available.lua** - Fetches available ESP-IDF versions from GitHub API (`api.github.com/repos/espressif/esp-idf/tags`). Marks v4.4.x and v5.0.x as LTS versions.

2. **pre_install.lua** - Minimal hook that returns version metadata. The actual download is skipped since ESP-IDF requires git cloning.

3. **post_install.lua** - Core installation logic:
   - Clones the ESP-IDF git repository for the requested version
   - Runs `install.sh` to set up ESP-IDF toolchains (target chips vary by version)
   - Creates wrapper scripts in `bin/` including `idf.py` wrapper and verification script

4. **env_keys.lua** - Configures environment variables:
   - Sets `IDF_PATH` to the installation directory
   - Adds ESP-IDF tools and Python virtual environment to `PATH`
   - Sets platform-specific library paths (`DYLD_LIBRARY_PATH` for macOS, `LD_LIBRARY_PATH` for Linux)
   - Hardcodes paths to Espressif toolchain binaries in `~/.espressif/tools/`

## Development Commands

### Formatting
```bash
mise run format      # Formats all Lua code using stylua
```

### Linting
```bash
mise run lint        # Runs hk check (includes luacheck + actionlint)
```

### Testing
```bash
mise run test        # Full integration test - links plugin, installs ESP-IDF 5.3.0, verifies setup
./validate-plugin.sh # Basic validation - checks file structure and Lua syntax
```

### CI
```bash
mise run ci          # Runs lint + test (same as GitHub Actions)
```

### Local Development
```bash
mise plugin link --force esp-idf .    # Link current directory as plugin
mise cache clear                       # Clear cache before testing changes
mise install esp-idf@5.3.0            # Test install of specific version
```

## Code Style

- **Lua version**: Lua 5.1 standard
- **Formatter**: stylua with 120 char column width, 4-space indentation
- **Linter**: luacheck configured in `.luacheckrc`
- **Globals**: `PLUGIN` is writable, `RUNTIME` is read-only from mise/vfox
- Luacheck ignores line length (631) and unused arguments (212) for hook signatures

## Important Implementation Details

### Version String Handling
ESP-IDF tags have a `v` prefix on GitHub (e.g., `v5.3.0`). The plugin:
- Strips the `v` prefix when returning versions from available.lua
- Re-adds the `v` prefix when cloning in post_install.lua

### Toolchain Target Selection
The post_install.lua hook selects ESP32 targets based on version:
- v4.x: `esp32,esp32s2`
- v5.0.x: `esp32,esp32s2,esp32s3,esp32c3`
- v5.1+: `all`

### Environment Variable Hardcoding
The env_keys.lua file contains hardcoded paths to specific toolchain versions in `~/.espressif/tools/`. These paths include version numbers (e.g., `esp-14.2.0_20241119`) which may need updating as ESP-IDF's toolchain dependencies evolve.

### Python Virtual Environment
ESP-IDF creates Python virtual environments at `~/.espressif/python_env/idf{major}.{minor}_py3.9_env/`. The plugin calculates this path dynamically from the ESP-IDF version string.

## Testing Strategy

The integration test (mise-tasks/test) performs a real installation:
1. Links the plugin locally
2. Installs ESP-IDF 5.3.0
3. Verifies `IDF_PATH` is set
4. Checks `idf.py --version` works
5. Runs the `esp-idf-verify` script

This test takes several minutes as it clones the full ESP-IDF repository and installs toolchains.
