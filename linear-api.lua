-- query  {
--   user(id: "{userid}")
--     id
--     name
--     assignedIssues {
--       nodes {
--         id
--         title
--         identifier
--         branchName
--       }
--     }
--   }
-- }
--
-- id: ${userid}
--
-- Get user id from
--
-- query {
--   viewer {
--     id
--     name
--   }
-- }
local M = {}
local curl = require("plenary.curl")

API_URL = "https://api.linear.app/graphql"
TOKEN = "ABC"

-- @param token string
-- @param query string
-- @return table
local function make_query(token, query)
  local headers = {
    ["Authorization"] = token,
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

-- @return string
function M.get_user_id()
  local query = '{ "query": "{ viewer { id name } }" }'
  local data = make_query(TOKEN, query)
  if data and data.data and data.data.viewer and data.data.viewer.id then
    return data.data.viewer.id
  else
    print("ID not found in response")
    return nil
  end
end

-- @param userid string
-- @return table
function M.get_assigned_issues(userid)
  local query = string.format(
    [[
    {"query" :
    "query {
      user(id: \"%s\") {
      id
      name
      assignedIssues {
        nodes {
          id
          title
          identifier
          branchName
        }
      }
    }
  }"}
  ]],
    userid
  )
  local data = make_query(TOKEN, query)
  if data and data.data and data.data.user and data.data.user.assignedIssues then
    return data.data.user.assignedIssues.nodes
  else
    print("Assigned issues not found in response")
    return nil
  end
end

return M
