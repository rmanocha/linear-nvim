local M = {}

local FILENAME = "/linear_api_key.txt"
local FILE_PATH = vim.fn.stdpath("data") .. FILENAME

function M.save_api_key(api_key)
  local file = io.open(FILE_PATH, "w") -- Open the file for writing
  if file then
    file:write(api_key)
    file:close()
  else
    print("Failed to open file for saving API key")
  end
end

function M.load_api_key()
  local file = io.open(FILE_PATH, "r") -- Open the file for reading
  if file then
    local api_key = file:read("*a") -- Read the entire contents of the file
    file:close()
    return api_key
  else
    return nil -- Return nil if the file doesn't exist
  end
end

return M
