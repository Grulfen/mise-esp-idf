-- hooks/env_keys.lua
-- Configures environment variables for ESP-IDF
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#envkeys-hook

function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.path

    -- ESP-IDF requires several environment variables to function properly
    -- These mirror what the export.sh script would normally set
    local env_vars = {
        -- IDF_PATH is the most critical environment variable for ESP-IDF
        {
            key = "IDF_PATH",
            value = mainPath,
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

    -- Note: Python virtual environment variables (VIRTUAL_ENV, IDF_PYTHON_ENV_PATH)
    -- and Python venv PATH entries are automatically provided by idf_tools.py export above

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
