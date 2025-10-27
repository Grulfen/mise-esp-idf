-- metadata.lua
-- Plugin metadata and configuration
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#metadata-lua

PLUGIN = { -- luacheck: ignore
    -- Required: Tool name (lowercase, no spaces)
    name = "esp-idf",

    -- Required: Plugin version (not the tool version)
    version = "1.0.0",

    -- Required: Brief description of the tool
    description = "A mise tool plugin for ESP-IDF (Espressif IoT Development Framework)",

    -- Required: Plugin author/maintainer
    author = "grulfen",

    -- Optional: Repository URL for plugin updates
    updateUrl = "https://github.com/grulfen/mise-esp-idf",

    -- Optional: Minimum mise runtime version required
    minRuntimeVersion = "0.2.0",

    -- Optional: Legacy version files this plugin can parse
    -- legacyFilenames = {
    --     ".esp-idf-version"
    -- }
}
