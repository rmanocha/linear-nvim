local M = {}
local curl = require("plenary.curl")

M._api_url = "https://api.linear.app/graphql"
M._api_key = ""
M._team_id = ""

function M.setup(api_key, team_id)
	M._api_key = api_key
	M._team_id = team_id
end

-- @param token string
-- @param query string
-- @return table
local function make_query(query)
	local headers = {
		["Authorization"] = M._api_key,
		["Content-Type"] = "application/json",
	}

	local resp = curl.post(M._api_url, {
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

-- @param api_key string
-- @return string
function M.get_user_id()
	local query = '{ "query": "{ viewer { id name } }" }'
	local data = make_query(query)
	if data and data.data and data.data.viewer and data.data.viewer.id then
		return data.data.viewer.id
	else
		print("ID not found in response")
		return nil
	end
end

-- @param api_key string
-- @param userid string
-- @return table
function M.get_assigned_issues(userid)
	-- Correctly format the JSON query string to ensure valid JSON
	local query = string.format(
		'{"query": "query { user(id: \\"%s\\") { id name assignedIssues(filter: {state: {type: {nin: [\\"completed\\", \\"canceled\\"]}}}) { nodes { id title identifier branchName description } } } }"}',
		userid
	)
	-- Execute the query using the make_query function
	local data = make_query(M._api_key, query)

	-- Check the structure of the returned data and extract the necessary information
	if data and data.data and data.data.user and data.data.user.assignedIssues then
		return data.data.user.assignedIssues.nodes
	else
		print("Assigned issues not found in response")
		return nil
	end
end

function M.get_teams()
	-- Correctly format the JSON query string to ensure valid JSON
	local query = '{ "query": "query { teams { nodes {id name }} }" }'

	-- Execute the query using the make_query function
	local data = make_query(query)

	-- Check the structure of the returned data and extract the necessary information
	if data and data.data and data.data.teams and data.data.teams.nodes then
		return data.data.teams.nodes
	else
		print("No teams found")
		return nil
	end
end

return M
