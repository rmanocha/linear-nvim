local M = {}
local linear_client = require("linear-nvim.client")
local key_store = require("linear-nvim.key-store")
local utils = require("linear-nvim.utils")

--- @type LinearNvimOptions
M.options = {}

--- @class LinearNvimIssueFields
M._issue_fields = {
    url = "Issue URL",
    branchName = "Branch Name",
    title = "Issue Title",
    identifier = "Issue Identifier",
    description = "Issue Description",
    id = "Issue ID",
}

--- @class LinearNvimOptions
local defaults = {
    issue_regex = "",
    issue_fields = {
        "url",
        "branchName",
        "title",
        "identifier",
        "description",
        "id",
    },
}

--- @param options LinearNvimOptions
function M.setup(options)
    options = options or {}
    M.options = vim.tbl_deep_extend("force", defaults, options)
    M.client =
        linear_client:setup(key_store.fetch_api_key, M.options.issue_fields)
end

--- @param issues table
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

--- @param issue table
--- @param issue_fields string[]
local function show_create_issues_result_picker(issue, issue_fields)
    local entries = {}

    for _, key in ipairs(issue_fields) do
        if issue[key] then
            local issue_desc = issue[key]
            if issue[key] == vim.NIL or issue[key] == nil then
                issue_desc = "No data avaialble"
            end
            table.insert(entries, {
                value = issue_desc,
                display = "Copy " .. M._issue_fields[key],
                ordinal = "Copy " .. M._issue_fields[key],
                description = issue_desc,
            })
        end
    end

    utils.show_telescope_picker(entries, "Issue created")
end
-- create a setup command the user has to call to provide an api key to use
-- once this key is saved, we can then setup key commands to trigger fetching
-- issues from Linear and display them in something similar to neotree or neotest
-- i.e. a panel

function M.show_user_id()
    print(M.client:get_user_id())
end

function M.show_assigned_issues()
    local issues = M.client:get_assigned_issues()
    if not issues then
        print("No issues found. Exiting...")
        return
    end

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
    local issue = M.client:create_issue(title, description)
    if issue ~= nil then
        print("Issue created successfully!")
        show_create_issues_result_picker(issue, M.options.issue_fields)
    else
        print("Failed to create issue")
    end
end

function M.show_issue_details()
    local issue_id = utils.get_current_word()
    if not M.options.issue_regex or M.options.issue_regex == "" then
        vim.notify("Issue regex not set", vim.log.levels.WARN)
        return
    end

    local parsed_issue_id = string.match(issue_id, M.options.issue_regex)
    if not parsed_issue_id then
        vim.notify("Not a valid issue ID: " .. issue_id, vim.log.levels.WARN)
        return
    end
    local issue = M.client:get_issue_details(parsed_issue_id)
    if issue == nil then
        return
    end
    show_create_issues_result_picker(issue, M.options.issue_fields)
end

return M
