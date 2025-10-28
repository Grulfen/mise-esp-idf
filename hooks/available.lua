-- hooks/available.lua
-- Returns a list of available versions for ESP-IDF
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#available-hook

function PLUGIN:Available(ctx)
    local http = require("http")
    local json = require("json")

    -- Fetch ESP-IDF versions from GitHub tags
    local repo_url = "https://api.github.com/repos/espressif/esp-idf/tags"

    local resp, err = http.get({
        url = repo_url,
    })

    if err ~= nil then
        error("Failed to fetch ESP-IDF versions: " .. err)
    end
    if resp.status_code ~= 200 then
        error("GitHub API returned status " .. resp.status_code .. ": " .. resp.body)
    end

    local tags = json.decode(resp.body)
    local result = {}

    -- Process ESP-IDF tags
    for _, tag_info in ipairs(tags) do
        local version = tag_info.name

        -- Clean up version string (remove 'v' prefix if present)
        version = version:gsub("^v", "")

        -- Skip non-release tags (like pre-release candidates)
        if version:match("^%d+%.%d+") then
            table.insert(result, {
                version = version,
            })
        end
    end

    return result
end
