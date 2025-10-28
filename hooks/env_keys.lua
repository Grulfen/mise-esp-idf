-- hooks/env_keys.lua
-- Configures environment variables for ESP-IDF
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#envkeys-hook

function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.path
    local sdkInfo = ctx.sdkInfo[PLUGIN.name]
    local version = sdkInfo.version

    -- Get the home directory
    local home = os.getenv("HOME")

    -- ESP-IDF requires several environment variables to function properly
    -- These mirror what the export.sh script would normally set
    local env_vars = {
        -- IDF_PATH is the most critical environment variable for ESP-IDF
        {
            key = "IDF_PATH",
            value = mainPath,
        },
        -- Add ESP-IDF tools directory to PATH (contains idf.py)
        {
            key = "PATH",
            value = mainPath .. "/tools",
        },
        -- Add our custom bin directory to PATH (contains verification script)
        {
            key = "PATH",
            value = mainPath .. "/bin",
        },
    }

    -- Add ESP-IDF component paths that export.sh normally adds
    local component_paths = {
        mainPath .. "/components/espcoredump",
        mainPath .. "/components/partition_table",
        mainPath .. "/components/app_update",
    }

    for _, comp_path in ipairs(component_paths) do
        table.insert(env_vars, {
            key = "PATH",
            value = comp_path,
        })
    end

    -- Add ESP-IDF installed tools paths (these are what export.sh discovers)
    local espressif_tools = home .. "/.espressif/tools"
    local tool_paths = {
        espressif_tools .. "/xtensa-esp-elf-gdb/16.2_20250324/xtensa-esp-elf-gdb/bin",
        espressif_tools .. "/riscv32-esp-elf-gdb/16.2_20250324/riscv32-esp-elf-gdb/bin",
        espressif_tools .. "/xtensa-esp-elf/esp-14.2.0_20241119/xtensa-esp-elf/bin",
        espressif_tools .. "/riscv32-esp-elf/esp-14.2.0_20241119/riscv32-esp-elf/bin",
        espressif_tools .. "/esp32ulp-elf/2.38_20240113/esp32ulp-elf/bin",
        espressif_tools .. "/openocd-esp32/v0.12.0-esp32-20250707/openocd-esp32/bin",
    }

    for _, tool_path in ipairs(tool_paths) do
        table.insert(env_vars, {
            key = "PATH",
            value = tool_path,
        })
    end

    -- Add Python virtual environment (critical for idf.py to work)
    -- Dynamically detect the Python venv directory instead of hardcoding Python version
    local python_venv_major = version:match("^(%d+)%.%d+")
    local python_venv_minor = version:match("^%d+%.(%d+)")
    local python_venv_pattern = home
        .. "/.espressif/python_env/idf"
        .. python_venv_major
        .. "."
        .. python_venv_minor
        .. "_py*_env"

    -- Find the actual Python venv directory using shell glob
    local find_cmd = "ls -d " .. python_venv_pattern .. " 2>/dev/null | head -n 1"
    local handle = io.popen(find_cmd)
    local python_venv_base = nil
    if handle then
        python_venv_base = handle:read("*l")
        handle:close()
    end

    -- If we found a Python venv, add it to the environment
    if python_venv_base and python_venv_base ~= "" then
        local python_venv_bin = python_venv_base .. "/bin"

        table.insert(env_vars, {
            key = "PATH",
            value = python_venv_bin,
        })

        -- Set VIRTUAL_ENV for Python virtual environment
        table.insert(env_vars, {
            key = "VIRTUAL_ENV",
            value = python_venv_base,
        })

        -- Set IDF_PYTHON_ENV_PATH (required by ESP-IDF)
        table.insert(env_vars, {
            key = "IDF_PYTHON_ENV_PATH",
            value = python_venv_base,
        })
    end

    -- Platform-specific additions
    if RUNTIME.osType == "Darwin" then -- luacheck: ignore 113
        -- macOS specific paths if needed
        table.insert(env_vars, {
            key = "DYLD_LIBRARY_PATH",
            value = mainPath .. "/tools/lib",
        })
    elseif RUNTIME.osType == "Linux" then -- luacheck: ignore 113
        -- Linux specific paths
        table.insert(env_vars, {
            key = "LD_LIBRARY_PATH",
            value = mainPath .. "/tools/lib",
        })
    end

    -- Note: ESP-IDF's export.sh doesn't set PYTHONPATH
    -- The Python virtual environment handles module paths automatically

    return env_vars
end
