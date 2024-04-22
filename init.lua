local M = {}
local linear_api = require("linear-api")
local key_store = require("key-store")

-- telescope imports
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local function show_picker(issues)
  pickers
    .new({}, {
      prompt_title = "Issues",
      finder = finders.new_table({
        results = issues,
      }),
      sorter = conf.generic_sorter({}),
    })
    :find()
end

-- create a setup command the user has to call to provide an api key to use
-- once this key is saved, we can then setup key commands to trigger fetching
-- issues from Linear and display them in something similar to neotree or neotest
-- i.e. a panel

function M.do_something()
  print("Hello world")
end

function M.show_user_id()
  print(linear_api.get_user_id(key_store.get_api_key()))
end

function M.show_assigned_issues()
  local api_key = key_store.get_api_key()
  local user_id = linear_api.get_user_id(api_key)
  local issues = linear_api.get_assigned_issues(api_key, user_id)

  local issue_titles = {}
  for _, issue in ipairs(issues) do
    -- print(issue.identifier .. " - " .. issue.title)
    table.insert(issue_titles, issue.identifier .. " - " .. issue.title)
  end

  show_picker(issue_titles)
end

return M
