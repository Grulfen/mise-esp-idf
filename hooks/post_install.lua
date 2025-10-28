-- hooks/post_install.lua
-- Performs ESP-IDF installation via git clone and install script
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#postinstall-hook

function PLUGIN:PostInstall(ctx)
    local sdkInfo = ctx.sdkInfo[PLUGIN.name]
    local path = sdkInfo.path
    local version = sdkInfo.version

    -- Ensure we have git available
    local gitCheck = os.execute("which git > /dev/null 2>&1")
    if gitCheck ~= 0 then
        error("git is required for ESP-IDF installation but was not found")
    end

    -- Remove the path if it exists (mise might have created an empty directory)
    os.execute("rm -rf " .. path)

    -- Clone ESP-IDF repository with the specific version (quietly)
    local gitCloneCmd = string.format(
        "git clone --quiet -b v%s --recursive https://github.com/espressif/esp-idf.git %s 2>&1",
        version,
        path
    )

    local cloneResult = os.execute(gitCloneCmd)
    if cloneResult ~= 0 then
        error("Failed to clone ESP-IDF repository for version " .. version)
    end

    -- Determine target chips based on version
    local targets = "all" -- Install all targets by default

    -- Run ESP-IDF install script (redirect output to reduce noise)
    local installCmd = string.format("cd %s && ./install.sh %s > /dev/null 2>&1", path, targets)
    local installResult = os.execute(installCmd)
    if installResult ~= 0 then
        error("Failed to install ESP-IDF tools")
    end
end
