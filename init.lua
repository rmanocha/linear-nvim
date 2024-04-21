-- Using `M` is a common Lua convention, `M` stand for module
-- It's used for a table that contains all exported functions and properties
-- (Exported because it's returned at the end of the file)
local M = {}
local linear_api = require("linear-api")
local key_store = require("key-store")

-- create a setup command the user has to call to provide an api key to use
-- once this key is saved, we can then setup key commands to trigger fetching
-- issues from Linear and display them in something similar to neotree or neotest
-- i.e. a panel

function M.do_something()
  print("Hello world")
end

function M.set_api_key()
  local api_key = vim.fn.input("Enter your API key: ")
  if api_key ~= "" then
    key_store.save_api_key(api_key)
    print("API key saved successfully!")
  else
    print("No API key entered.")
  end
end

function M.show_user_id()
  print(linear_api.get_user_id())
end

function M.show_assigned_issues()
  print(linear_api.get_assigned_issues(linear_api.get_user_id()))
end

return M
