-- hooks/env_keys.lua
-- Configures environment variables for ESP-IDF
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#envkeys-hook

function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.path
    local home = os.getenv("HOME")
    local idf_tools_path = os.getenv("IDF_TOOLS_PATH") or (home and home .. "/.espressif")

    local function shell_quote(value)
        return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
    end

    local function read_first_line(command)
        local handle = io.popen(command)
        if not handle then
            return nil
        end

        local line = handle:read("*l")
        handle:close()

        if line and line ~= "" then
            return line
        end
        return nil
    end

    local function find_idf_python_env_path()
        local idf_version = tostring(ctx.version):match("^(%d+%.%d+)")
        if not idf_tools_path or not idf_version then
            return nil
        end

        local find_cmd = string.format(
            'for py in %s/python_env/idf%s_py*_env/bin/python; do [ -x "$py" ] && dirname "$(dirname "$py")" && break; done',
            shell_quote(idf_tools_path),
            idf_version
        )
        return read_first_line(find_cmd)
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
    local idf_python_env_path = find_idf_python_env_path()

    local function add_path_entry(path_entry)
        if path_entry ~= "$PATH" and path_entry ~= "" and not path_entries[path_entry] then
            path_entries[path_entry] = true
            table.insert(env_vars, {
                key = "PATH",
                value = path_entry,
            })
        end
    end

    -- Ask ESP-IDF for the environment in a minimal shell so it emits the full
    -- environment instead of diffing against the currently active project.
    local error_file = os.tmpname()
    local python = idf_python_env_path and (idf_python_env_path .. "/bin/python") or "python3"
    local clean_env = {
        "env -i",
        "PATH='/usr/bin:/bin:/usr/sbin:/sbin'",
        "IDF_PATH=" .. shell_quote(mainPath),
    }
    if home then
        table.insert(clean_env, "HOME=" .. shell_quote(home))
    end
    if idf_tools_path then
        table.insert(clean_env, "IDF_TOOLS_PATH=" .. shell_quote(idf_tools_path))
    end
    local idf_tools_cmd = string.format(
        "%s %s %s export --format=key-value 2>%s",
        table.concat(clean_env, " "),
        shell_quote(python),
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

    -- Add deterministic fallback PATH entries if ESP-IDF did not emit them.
    if idf_python_env_path and idf_python_env_path ~= "" then
        add_path_entry(idf_python_env_path .. "/bin")
    end
    add_path_entry(mainPath .. "/tools")

    -- Platform-specific additions
    if RUNTIME.osType == "darwin" then -- luacheck: ignore 113
        -- macOS specific paths if needed
        table.insert(env_vars, {
            key = "DYLD_LIBRARY_PATH",
            value = mainPath .. "/tools/lib",
        })
    elseif RUNTIME.osType == "linux" then -- luacheck: ignore 113
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
