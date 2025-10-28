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

    -- Clone ESP-IDF repository with the specific version
    local gitCloneCmd =
        string.format("git clone -b v%s --recursive https://github.com/espressif/esp-idf.git %s", version, path)

    print("Cloning ESP-IDF v" .. version .. "...")
    local cloneResult = os.execute(gitCloneCmd)
    if cloneResult ~= 0 then
        error("Failed to clone ESP-IDF repository for version " .. version)
    end

    -- Determine target chips based on version
    local targets = "all" -- Install all targets by default

    -- Run ESP-IDF install script
    print("Installing ESP-IDF tools for targets: " .. targets)
    local installCmd = string.format("cd %s && ./install.sh %s", path, targets)
    local installResult = os.execute(installCmd)
    if installResult ~= 0 then
        error("Failed to install ESP-IDF tools")
    end

    -- Create scripts for ESP-IDF usage
    os.execute("mkdir -p " .. path .. "/bin")

    -- Create a verification script
    local verifyScript = path .. "/bin/esp-idf-verify"
    local file = io.open(verifyScript, "w")
    if file then
        file:write("#!/bin/bash\n")
        file:write("# ESP-IDF verification script\n")
        file:write("source " .. path .. "/export.sh > /dev/null 2>&1\n")
        file:write("if command -v idf.py > /dev/null 2>&1; then\n")
        file:write('  echo "ESP-IDF ' .. version .. ' is properly installed"\n')
        file:write("  exit 0\n")
        file:write("else\n")
        file:write('  echo "ESP-IDF installation verification failed"\n')
        file:write("  exit 1\n")
        file:write("fi\n")
        file:close()
        os.execute("chmod +x " .. verifyScript)
    end

    print("ESP-IDF " .. version .. " installation completed successfully")
end
