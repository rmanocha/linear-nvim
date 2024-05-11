local M = {}
local linear_client = require("linear-nvim.client")
local key_store = require("linear-nvim.key-store")
local utils = require("linear-nvim.utils")

function M.setup()
	local api_key = key_store.get_api_key()
	local team_id = key_store.get_or_set_team_id()
	M._client = linear_client:setup(api_key, team_id)
end

local function show_issues_picker(issues)
	-- Prepare entries for the picker from the issues map
	local entries = {}
	for display_key, data_bag in pairs(issues) do
		table.insert(entries, {
			value = data_bag.branch_name, -- This is what will be copied to the clipboard
			display = display_key, -- How the entry will be displayed
			ordinal = display_key, -- Used for sorting and searching
			description = data_bag.description, -- Additional information that can be displayed
		})
	end

	utils.show_telescope_picker(entries, "Issues")
end

local function show_create_issues_result_picker(issue)
	local entries = {
		{
			value = issue.url,
			display = "Copy Issue URL",
			ordinal = "Copy Issue URL",
			description = issue.url,
		},
		{
			value = issue.branchName,
			display = "Copy Branch Name",
			ordinal = "Copy Branch Name",
			description = issue.branchName,
		},
		{
			value = issue.title,
			display = "Copy Issue Title",
			ordinal = "Copy Issue Title",
			description = issue.title,
		},
		{
			value = issue.identifier,
			display = "Copy Issue Identifier",
			ordinal = "Copy Issue Identifier",
			description = issue.identifier,
		},
	}

	utils.show_telescope_picker(entries, "Issue created")
end

-- create a setup command the user has to call to provide an api key to use
-- once this key is saved, we can then setup key commands to trigger fetching
-- issues from Linear and display them in something similar to neotree or neotest
-- i.e. a panel

function M.show_user_id()
	print(M._client:get_user_id())
end

function M.show_assigned_issues()
	local issues = M._client:get_assigned_issues()

	local issue_titles = {}
	for _, issue in ipairs(issues) do
		local description = issue.description
		if description == vim.NIL or description == nil then
			description = "No description available"
		end
		issue_titles[issue.identifier .. " - " .. issue.title] =
			{ branch_name = issue.branchName, description = description }
	end

	show_issues_picker(issue_titles)
end

function M.create_issue()
	local full_selection = utils.get_visual_selection()
	local title, description = full_selection:match("([^\n]*)\n(.*)")

	-- If there is no newline, the whole selection is the title
	if not title then
		title = full_selection
		description = ""
	end
	if title == "" then
		title = vim.fn.input("Enter the title of the issue: ")
	end
	local issue = M._client:create_issue(title, description)
	if issue ~= nil then
		print("Issue created successfully!")
		show_create_issues_result_picker(issue)
	else
		print("Failed to create issue")
	end
end

return M
