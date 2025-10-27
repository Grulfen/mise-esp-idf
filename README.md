# mise-esp-idf

A [mise](https://mise.jdx.dev) tool plugin for [ESP-IDF](https://github.com/espressif/esp-idf) (Espressif IoT Development Framework).

ESP-IDF is the official development framework for Espressif ESP32 series of chips, providing a comprehensive set of tools, APIs, and components for developing IoT applications.

## Installation

Install this plugin using mise:

```bash
mise plugin install esp-idf https://github.com/grulfen/mise-esp-idf.git
```

## Usage

Install a specific ESP-IDF version:

```bash
# Install latest version
mise install esp-idf@latest

# Install specific version
mise install esp-idf@5.3.0

# Install LTS version  
mise install esp-idf@5.0.7
```

Set ESP-IDF version for your project:

```bash
# Use ESP-IDF globally
mise use -g esp-idf@5.3.0

# Use ESP-IDF for current project only
mise use esp-idf@5.3.0
```

This will create a `.mise.toml` file in your project directory with the ESP-IDF version specification.

## Environment Setup

Once installed and activated, the plugin automatically sets up:

- `IDF_PATH` - Points to the ESP-IDF installation directory
- `PATH` - Includes ESP-IDF tools and utilities
- `PYTHONPATH` - Includes ESP-IDF Python modules
- Platform-specific library paths (`LD_LIBRARY_PATH` on Linux, `DYLD_LIBRARY_PATH` on macOS)

You can verify the installation by running:

```bash
idf.py --version
```

## Version Management for Teams

Create a `.mise.toml` file in your project root to ensure all developers use the same ESP-IDF version:

```toml
[tools]
esp-idf = "5.3.0"
```

Team members can then run:

```bash
mise install  # Installs the specified ESP-IDF version
```

## Supported Versions

This plugin supports all ESP-IDF releases available on GitHub. LTS versions are marked accordingly:

- 4.4.x series (LTS)
- 5.0.x series (LTS) 
- 5.1.x+ series (Latest)

## Requirements

- git (for cloning the ESP-IDF repository)
- Python 3.9+ 
- Platform-specific build tools (automatically installed by ESP-IDF's install script)

## Development and Testing

### Local Testing

1. Link the plugin for development:
```bash
mise plugin link --force esp-idf .
```

2. Test installation of a specific version:
```bash
mise install esp-idf@5.3.0
```

3. Test environment setup:
```bash
mise use esp-idf@5.3.0
echo $IDF_PATH
idf.py --version
```

### Debugging

Enable debug output to troubleshoot installation issues:
```bash
MISE_DEBUG=1 mise install esp-idf@5.3.0
```

## How It Works

This plugin:

1. **Available Hook**: Fetches ESP-IDF versions from GitHub API
2. **PreInstall Hook**: Prepares for git-based installation  
3. **PostInstall Hook**: Clones ESP-IDF repository and runs `install.sh`
4. **EnvKeys Hook**: Sets up `IDF_PATH` and other required environment variables

The plugin mimics the standard ESP-IDF setup process but manages it through mise for easy version switching.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT