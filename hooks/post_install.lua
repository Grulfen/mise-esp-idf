-- hooks/post_install.lua
-- Performs ESP-IDF installation via git clone and install script
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#postinstall-hook

function PLUGIN:PostInstall(ctx)
    local sdkInfo = ctx.sdkInfo[PLUGIN.name]
    local path = sdkInfo.path
    local version = sdkInfo.version

    local function shell_quote(value)
        return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
    end

    -- Ensure we have git available
    local gitCheck = os.execute("which git > /dev/null 2>&1")
    if gitCheck ~= 0 then
        error("git is required for ESP-IDF installation but was not found")
    end

    -- Clone ESP-IDF repository with the specific version (quietly)
    local gitCloneCmd = string.format(
        "git clone --quiet -b v%s --recursive https://github.com/espressif/esp-idf.git %s 2>&1",
        version,
        shell_quote(path)
    )

    local cloneResult = os.execute(gitCloneCmd)
    if cloneResult ~= 0 then
        error("Failed to clone ESP-IDF repository for version " .. version)
    end

    -- Run ESP-IDF install script in a clean environment so a previously active
    -- ESP-IDF shell cannot leak variables into this install.
    local installCmd = string.format(
        "env -u IDF_PATH -u IDF_PYTHON_ENV_PATH -u ESP_IDF_VERSION -u IDF_DEACTIVATE_FILE_PATH IDF_PATH=%s /bin/sh -c 'cd %s && ./install.sh all' > /dev/null 2>&1",
        shell_quote(path),
        shell_quote(path)
    )
    local installResult = os.execute(installCmd)
    if installResult ~= 0 then
        error("Failed to install ESP-IDF tools")
    end
end
