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
    }

    -- Use idf_tools.py to get the correct environment for this ESP-IDF version
    local idf_tools_cmd = string.format("python3 %s/tools/idf_tools.py export --format=key-value 2>/dev/null", mainPath)
    local handle = io.popen(idf_tools_cmd)
    if handle then
        for line in handle:lines() do
            -- Parse key=value pairs
            local key, value = line:match("^([^=]+)=(.*)$")
            if key and value then
                if key == "PATH" then
                    -- Split PATH by colon and add each directory (except the $PATH placeholder)
                    for path_entry in value:gmatch("([^:]+)") do
                        if path_entry ~= "$PATH" and path_entry ~= "" then
                            table.insert(env_vars, {
                                key = "PATH",
                                value = path_entry,
                            })
                        end
                    end
                elseif key ~= "IDF_DEACTIVATE_FILE_PATH" then
                    -- Add other environment variables (skip the temp deactivate file)
                    table.insert(env_vars, {
                        key = key,
                        value = value,
                    })
                end
            end
        end
        handle:close()
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
    local py_handle = io.popen(find_cmd)
    local python_venv_base = nil
    if py_handle then
        python_venv_base = py_handle:read("*l")
        py_handle:close()
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
