--- @class LinearClient
--- @field callback_for_api_key function
local LinearClient = {}
local curl = require("plenary.curl")
local log = require("plenary.log")
local utils = require("linear-nvim.utils")

API_URL = "https://api.linear.app/graphql"
LinearClient._api_key = ""
LinearClient._team_id = ""
LinearClient.callback_for_api_key = nil
LinearClient._issue_fields = nil
LinearClient._default_labels = {}

--- @param api_key string
--- @param query string
--- @return table?
LinearClient._make_query = function(api_key, query)
    local headers = {
        ["Authorization"] = api_key,
        ["Content-Type"] = "application/json",
    }

    local resp = curl.post(API_URL, {
        body = query,
        headers = headers,
    })

    if resp.status ~= 200 then
        log.error(
            string.format(
                "Failed to fetch data: HTTP status %s, Response body: %s",
                resp.status,
                resp.body
            )
        )
        return nil
    end

    local data = vim.json.decode(resp.body)
    return data
end

--- @param callback_for_api_key function
--- @param issue_fields string[]
--- @param default_labels? string[]
--- @return LinearClient
function LinearClient:setup(callback_for_api_key, issue_fields, default_labels)
    self.callback_for_api_key = callback_for_api_key
    self._issue_fields = issue_fields
    self._default_labels = default_labels or {}

    return self
end

--- @return string
function LinearClient:fetch_api_key()
    if
        (not self._api_key or self._api_key == "") and self.callback_for_api_key
    then
        local api_key = self.callback_for_api_key()
        if api_key ~= nil and api_key ~= "" then
            self._api_key = api_key
        else
            log.error("API key not set.")
        end
    end
    return self._api_key
end

--- @param callback function
function LinearClient:fetch_team_id(callback)
    if self._team_id and self._team_id ~= "" then
        callback(self._team_id)
        return
    end

    local teams = self:get_teams()
    if teams == nil then
        vim.notify("No teams found.", vim.log.levels.ERROR)
        log.error("No teams found.", vim.log.levels.ERROR)
        callback(nil)
        return
    end

    if #teams == 1 then
        self._team_id = teams[1].id
        log.info(
            "Only one team found, using team "
                .. teams[1].name
                .. " automatically.",
            vim.log.levels.INFO
        )
        callback(self._team_id)
        return
    end

    local team_options = {}
    for _, team in ipairs(teams) do
        table.insert(team_options, { text = team.name, id = team.id })
    end

    vim.ui.select(team_options, {
        prompt = "Select a team:",
        format_item = function(item)
            return item.text
        end,
    }, function(choice)
        if choice then
            self._team_id = choice.id
            vim.notify(
                "Selected team " .. choice.text .. " saved successfully!",
                vim.log.levels.INFO
            )
            log.info(
                "Selected team " .. choice.text .. " saved successfully!",
                vim.log.levels.INFO
            )
            callback(self._team_id)
        else
            vim.notify("Team selection cancelled.", vim.log.levels.WARN)
            log.warn("Team selection cancelled.")
            callback(nil)
        end
    end)
end

--- @return string?
function LinearClient:get_user_id()
    local query = '{ "query": "{ viewer { id name } }" }'
    local data = self._make_query(self:fetch_api_key(), query)
    if data and data.data and data.data.viewer and data.data.viewer.id then
        return data.data.viewer.id
    else
        log.error("User ID not found in response")
        return nil
    end
end

--- @return table?
function LinearClient:get_assigned_issues()
    local query = string.format(
        '{"query": "query { user(id: \\"%s\\") { id name assignedIssues(filter: {state: {type: {nin: [\\"completed\\", \\"canceled\\"]}}}) { nodes { id title identifier branchName description } } } }"}',
        self:get_user_id()
    )
    local data = self._make_query(self:fetch_api_key(), query)

    if
        data
        and data.data
        and data.data.user
        and data.data.user.assignedIssues
    then
        return data.data.user.assignedIssues.nodes
    else
        log.error("Assigned issues not found in response")
        return nil
    end
end

--- @return table?
function LinearClient:get_teams()
    local query = '{ "query": "query { teams { nodes {id name }} }" }'

    local data = self._make_query(self:fetch_api_key(), query)

    if data and data.data and data.data.teams and data.data.teams.nodes then
        return data.data.teams.nodes
    else
        log.error("No teams found")
        return nil
    end
end

--- @param labels string[]
--- @return string
local function convertDefaultLabelsToGQLArray(labels)
    local labelArray = {}
    for _, label in ipairs(labels) do
        table.insert(labelArray, string.format('\\"%s\\"', label))
    end
    return string.format("[%s]", table.concat(labelArray, ","))
end

--- @param title string
--- @param description string
--- @param callback function(issue: table?)
function LinearClient:create_issue(title, description, callback)
    local parsed_title = utils.escape_json_string(title)
    local issue_fields_query = table.concat(self._issue_fields, " ")
    local labels_to_attach =
        convertDefaultLabelsToGQLArray(self._default_labels)
    local user_id = self:get_user_id()

    if not user_id then
        vim.notify("Failed to get user ID", vim.log.levels.ERROR)
        callback(nil)
        return
    end

    self:fetch_team_id(function(team_id)
        if not team_id then
            vim.notify("Failed to get team ID", vim.log.levels.ERROR)
            callback(nil)
            return
        end

        local query = string.format(
            '{"query": "mutation IssueCreate { issueCreate(input: {title: \\"%s\\" teamId: \\"%s\\" assigneeId: \\"%s\\" labelIds: %s}) { success issue { %s } } }"}',
            parsed_title,
            team_id,
            user_id,
            labels_to_attach,
            issue_fields_query
        )

        local data = self._make_query(self:fetch_api_key(), query)

        if
            data
            and data.data
            and data.data.issueCreate
            and data.data.issueCreate.success
            and data.data.issueCreate.success == true
            and data.data.issueCreate.issue
        then
            callback(data.data.issueCreate.issue)
        else
            vim.notify("Issue not found in response", vim.log.levels.ERROR)
            callback(nil)
        end
    end)
end

--- @param issue_id string
--- @return table?
function LinearClient:get_issue_details(issue_id)
    local issue_fields_query = table.concat(self._issue_fields, " ")
    local query = string.format(
        '{"query":"query { issue(id: \\"%s\\") { %s }}"}',
        issue_id,
        issue_fields_query
    )

    local data = self._make_query(self:fetch_api_key(), query)

    if data and data.data and data.data.issue then
        return data.data.issue
    else
        vim.notify("Issue not found in response", vim.log.levels.ERROR)
        return nil
    end
end

return LinearClient
