local LinearClient = {}
local curl = require("plenary.curl")
local utils = require("linear-nvim.utils")

API_URL = "https://api.linear.app/graphql"
LinearClient._api_key = ""
LinearClient._team_id = ""
LinearClient.callback_for_api_key = nil

-- @param api_key string
-- @param query string
-- @return table
local function make_query(api_key, query)
	local headers = {
		["Authorization"] = api_key,
		["Content-Type"] = "application/json",
	}

	local resp = curl.post(API_URL, {
		body = query,
		headers = headers,
	})

	if resp.status ~= 200 then
		print(string.format("Failed to fetch data: HTTP status %s, Response body: %s", resp.status, resp.body))
		return nil
	end

	local data = vim.json.decode(resp.body)
	return data
end

-- @param callback_for_api_key function
-- @return LinearClient
function LinearClient:setup(callback_for_api_key)
	self.callback_for_api_key = callback_for_api_key
	return self
end

-- @return string
function LinearClient:fetch_api_key()
	if (not self._api_key or self._api_key == "") and self.callback_for_api_key then
		self._api_key = self.callback_for_api_key()
	end
	return self._api_key
end

-- @return string
function LinearClient:fetch_team_id()
	if not self._team_id or self._team_id == "" then
		local teams = self:get_teams()
		if teams ~= nil then
			local options = {}
			for i, team in ipairs(teams) do
				table.insert(options, string.format("%d: %s", i, team.name))
			end
			local selected_team = vim.fn.inputlist(options)
			self._team_id = teams[selected_team].id
			print("Selected team " .. teams[selected_team].name .. " saved successfully!")
		else
			print("No team ID selected.")
		end
	end
	return self._team_id
end

-- @return string
function LinearClient:get_user_id()
	local query = '{ "query": "{ viewer { id name } }" }'
	local data = make_query(self:fetch_api_key(), query)
	if data and data.data and data.data.viewer and data.data.viewer.id then
		return data.data.viewer.id
	else
		print("ID not found in response")
		return nil
	end
end

-- @return table
function LinearClient:get_assigned_issues()
	local query = string.format(
		'{"query": "query { user(id: \\"%s\\") { id name assignedIssues(filter: {state: {type: {nin: [\\"completed\\", \\"canceled\\"]}}}) { nodes { id title identifier branchName description } } } }"}',
		self:get_user_id()
	)
	local data = make_query(self:fetch_api_key(), query)

	if data and data.data and data.data.user and data.data.user.assignedIssues then
		return data.data.user.assignedIssues.nodes
	else
		print("Assigned issues not found in response")
		return nil
	end
end

function LinearClient:get_teams()
	local query = '{ "query": "query { teams { nodes {id name }} }" }'

	local data = make_query(self:fetch_api_key(), query)

	if data and data.data and data.data.teams and data.data.teams.nodes then
		return data.data.teams.nodes
	else
		print("No teams found")
		return nil
	end
end

-- @param title string
-- @param description string
function LinearClient:create_issue(title, description)
	local parsed_title = utils.escape_json_string(title)
	--local parsed_description = utils.escape_json_string(description)
	local query = string.format(
		-- can't figure out how to send newlines in the description. skipping it for now
		--'{"query": "mutation IssueCreate { issueCreate(input: {title: \\"%s\\" description: \\"%s\\" teamId: \\"%s\\" assigneeId: \\"%s\\"}) { success issue { id title identifier branchName url} } }"}',
		'{"query": "mutation IssueCreate { issueCreate(input: {title: \\"%s\\" teamId: \\"%s\\" assigneeId: \\"%s\\"}) { success issue { id title identifier branchName url} } }"}',
		parsed_title,
		--parsed_description,
		self:fetch_team_id(),
		self:get_user_id()
	)

	local data = make_query(self:fetch_api_key(), query)

	if
		data
		and data.data
		and data.data.issueCreate
		and data.data.issueCreate.success
		and data.data.issueCreate.success == true
		and data.data.issueCreate.issue
	then
		return data.data.issueCreate.issue
	else
		print("Issue not found in response")
		return nil
	end
end

return LinearClient
