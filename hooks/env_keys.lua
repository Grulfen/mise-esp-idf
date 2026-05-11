-- hooks/env_keys.lua
-- Configures environment variables for ESP-IDF
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#envkeys-hook

function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.path

    local function shell_quote(value)
        return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
    end

    -- ESP-IDF requires several environment variables to function properly
    -- These mirror what the export.sh script would normally set
    local env_vars = {
        -- IDF_PATH is the most critical environment variable for ESP-IDF
        {
            key = "IDF_PATH",
            value = mainPath,
        },
    }
    local path_entries = {}
    local idf_python_env_path = nil

    local function add_path_entry(path_entry)
        if path_entry ~= "$PATH" and path_entry ~= "" and not path_entries[path_entry] then
            path_entries[path_entry] = true
            table.insert(env_vars, {
                key = "PATH",
                value = path_entry,
            })
        end
    end

    -- Ask ESP-IDF for the environment in a clean shell so previously active
    -- ESP-IDF variables do not leak across projects or versions.
    local error_file = os.tmpname()
    local idf_tools_cmd = string.format(
        "env -u IDF_PATH -u IDF_PYTHON_ENV_PATH -u ESP_IDF_VERSION -u IDF_DEACTIVATE_FILE_PATH IDF_PATH=%s python3 %s export --format=key-value 2>%s",
        shell_quote(mainPath),
        shell_quote(mainPath .. "/tools/idf_tools.py"),
        shell_quote(error_file)
    )
    local handle = io.popen(idf_tools_cmd)
    if handle then
        for line in handle:lines() do
            -- Parse key=value pairs
            local key, value = line:match("^([^=]+)=(.*)$")
            if key and value then
                if key == "PATH" then
                    -- Split PATH by colon and add each directory (except the $PATH placeholder)
                    for path_entry in value:gmatch("([^:]+)") do
                        add_path_entry(path_entry)
                    end
                elseif key ~= "IDF_DEACTIVATE_FILE_PATH" then
                    if key == "IDF_PYTHON_ENV_PATH" then
                        idf_python_env_path = value
                    end

                    -- Add other environment variables (skip the temp deactivate file)
                    table.insert(env_vars, {
                        key = key,
                        value = value,
                    })
                end
            end
        end
        local ok, _, code = handle:close()

        if not ok then
            local error_handle = io.open(error_file, "r")
            local error_output = ""
            if error_handle then
                error_output = error_handle:read("*a") or ""
                error_handle:close()
            end
            os.remove(error_file)
            error(
                string.format(
                    "Failed to export ESP-IDF environment for %s (exit code %s): %s",
                    mainPath,
                    tostring(code),
                    error_output ~= "" and error_output or "no error output"
                )
            )
        end

        os.remove(error_file)
    end

    -- Older ESP-IDF versions only emit these PATH entries when they are not
    -- already present in PATH. mise needs the hook result to be deterministic.
    if idf_python_env_path and idf_python_env_path ~= "" then
        add_path_entry(idf_python_env_path .. "/bin")
    end
    add_path_entry(mainPath .. "/tools")

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
