local M = {}
local curl = require("plenary.curl")

API_URL = "https://api.linear.app/graphql"

-- @param token string
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

-- @param api_key string
-- @return string
function M.get_user_id(api_key)
  local query = '{ "query": "{ viewer { id name } }" }'
  local data = make_query(api_key, query)
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
function M.get_assigned_issues(api_key, userid)
  -- Correctly format the JSON query string to ensure valid JSON
  local query = string.format(
    '{"query": "query { user(id: \\"%s\\") { id name assignedIssues(filter: {state: {type: {nin: [\\"completed\\", \\"canceled\\"]}}}) { nodes { id title identifier branchName description } } } }"}',
    userid
  )
  -- Execute the query using the make_query function
  local data = make_query(api_key, query)

  -- Check the structure of the returned data and extract the necessary information
  if data and data.data and data.data.user and data.data.user.assignedIssues then
    return data.data.user.assignedIssues.nodes
  else
    print("Assigned issues not found in response")
    return nil
  end
end

-- @param api_key string
-- @param userid string
-- @param title string
-- @param description string
-- @param teamid string
function M.create_issue(api_key, userid, title, description, teamid)
  -- Correctly format the JSON query string to ensure valid JSON
  local query = string.format(
    '{"query": "mutation IssueCreate { issueCreate(input: {title: \\"%s\\" description: \\"%s\\" teamId: \\"%s\\" assigneeId: \\"%s\\"}) { success issue { id title identifier branchName url} } }"}',
    title,
    description,
    teamid,
    userid
  )
  -- Execute the query using the make_query function
  local data = make_query(api_key, query)

  -- Check the structure of the returned data and extract the necessary information
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

return M
