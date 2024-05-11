local M = {}

local FILENAME = "/linear_api_key.txt"
local FILE_PATH = vim.fn.stdpath("data") .. FILENAME

local function save_api_key(api_key)
	local file = io.open(FILE_PATH, "w") -- Open the file for writing
	if file then
		file:write(api_key)
		file:close()
	else
		print("Failed to open file for saving API key")
	end
end

function M.fetch_api_key()
	local file = io.open(FILE_PATH, "r") -- Open the file for reading
	if file then
		local api_key = file:read("*a") -- Read the entire contents of the file
		file:close()
		-- strip all whitespace
		api_key = string.gsub(api_key, "%s", "")
		return api_key
	else
		local api_key = vim.fn.input("Enter your API key: ")
		if api_key ~= "" then
			save_api_key(api_key)
		else
			print("No API key entered.")
		end
	end
end

return M
