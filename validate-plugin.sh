#!/bin/bash
# Simple validation script for ESP-IDF mise plugin

echo "🔍 Validating ESP-IDF mise plugin structure..."

# Check if all required files exist
required_files=(
    "metadata.lua"
    "hooks/available.lua"
    "hooks/pre_install.lua"
    "hooks/post_install.lua"
    "hooks/env_keys.lua"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        missing_files+=("$file")
    fi
done

if [[ ${#missing_files[@]} -gt 0 ]]; then
    echo "❌ Missing required files:"
    printf '  - %s\n' "${missing_files[@]}"
    exit 1
else
    echo "✅ All required hook files present"
fi

# Check Lua syntax for all hook files
echo "🔍 Checking Lua syntax..."
lua_errors=()

for file in hooks/*.lua metadata.lua; do
    if ! lua -e "dofile('$file')" 2>/dev/null; then
        lua_errors+=("$file")
    fi
done

if [[ ${#lua_errors[@]} -gt 0 ]]; then
    echo "❌ Lua syntax errors in:"
    printf '  - %s\n' "${lua_errors[@]}"
    exit 1
else
    echo "✅ All Lua files have valid syntax"
fi

# Check that ESP-IDF specific content is present
echo "🔍 Checking ESP-IDF specific configuration..."

if grep -q "esp-idf" metadata.lua; then
    echo "✅ Plugin name configured for ESP-IDF"
else
    echo "❌ Plugin name not configured for ESP-IDF"
    exit 1
fi

if grep -q "espressif/esp-idf" hooks/available.lua; then
    echo "✅ Available hook points to ESP-IDF repository"
else
    echo "❌ Available hook not configured for ESP-IDF"
    exit 1
fi

if grep -q "IDF_PATH" hooks/env_keys.lua; then
    echo "✅ Environment setup includes IDF_PATH"
else
    echo "❌ Environment setup missing IDF_PATH"
    exit 1
fi

if grep -q "git clone.*esp-idf" hooks/post_install.lua; then
    echo "✅ Post-install hook configured for git cloning"
else
    echo "❌ Post-install hook not configured for ESP-IDF"
    exit 1
fi

echo ""
echo "🎉 ESP-IDF mise plugin validation completed successfully!"
echo ""
echo "📋 Plugin Summary:"
echo "  - Name: esp-idf"
echo "  - Repository: https://github.com/espressif/esp-idf"
echo "  - Installation method: Git clone + install.sh"
echo "  - Environment: IDF_PATH, PATH, PYTHONPATH"
echo ""
echo "🚀 Ready for use! Install with:"
echo "   mise plugin install esp-idf /path/to/this/plugin"
echo "   mise install esp-idf@5.3.0"