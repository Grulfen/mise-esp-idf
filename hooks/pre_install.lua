-- hooks/pre_install.lua
-- Returns download information for ESP-IDF
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#preinstall-hook

function PLUGIN:PreInstall(ctx)
    local version = ctx.version

    -- ESP-IDF uses git repository cloning instead of downloading releases
    -- We'll return a special marker that indicates post_install should handle the git clone
    return {
        version = version,
        -- No URL - we'll handle git clone in post_install
        note = "Installing ESP-IDF " .. version .. " from git repository",
    }
end
