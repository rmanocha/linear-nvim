local log = require("plenary.log")
local M = {}

local FILENAME = "/linear_api_key.txt"
local FILE_PATH = vim.fn.stdpath("data") .. FILENAME

local function save_api_key(api_key)
    local file = io.open(FILE_PATH, "w") -- Open the file for writing
    if file then
        file:write(api_key)
        file:close()
    else
        log.warn("Failed to open file for saving API key")
    end
end

function M.fetch_api_key()
    local file = io.open(FILE_PATH, "r") -- Open the file for reading
    local api_key = ""
    if file then
        api_key = file:read("*a") -- Read the entire contents of the file
        file:close()
        -- strip all whitespace
        api_key = string.gsub(api_key, "%s", "")
    else
        api_key = vim.fn.input("Enter your API key: ")
        if api_key ~= "" then
            save_api_key(api_key)
        else
            log.warn("No API key entered.")
            return nil
        end
    end
    return api_key
end

return M
