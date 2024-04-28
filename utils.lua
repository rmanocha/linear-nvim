local M = {}

local function tbl_length(T)
  local count = 0
  for _ in pairs(T) do
    count = count + 1
  end
  return count
end

function M.get_visual_selection()
  -- this will exit visual mode
  -- use 'gv' to reselect the text
  local _, csrow, cscol, cerow, cecol
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "" then
    -- if we are in visual mode use the live position
    _, csrow, cscol, _ = unpack(vim.fn.getpos("."))
    _, cerow, cecol, _ = unpack(vim.fn.getpos("v"))
    if mode == "V" then
      -- visual line doesn't provide columns
      cscol, cecol = 0, 999
    end
    -- NOTE: not required since commit: e8b2093
    -- exit visual mode
    -- vim.api.nvim_feedkeys(
    --   vim.api.nvim_replace_termcodes("<Esc>",
    --     true, false, true), "n", true)
  else
    -- otherwise, use the last known visual position
    _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
    _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
  end
  -- swap vars if needed
  if cerow < csrow then
    csrow, cerow = cerow, csrow
  end
  if cecol < cscol then
    cscol, cecol = cecol, cscol
  end
  local lines = vim.fn.getline(csrow, cerow)
  -- local n = cerow-csrow+1
  local n = tbl_length(lines)
  if n <= 0 then
    return ""
  end
  lines[n] = string.sub(lines[n], 1, cecol)
  lines[1] = string.sub(lines[1], cscol)
  return table.concat(lines, "\n"),
    {
      start = { line = csrow, char = cscol },
      ["end"] = { line = cerow, char = cecol },
    }
end

-- @param str string
-- @return string
function M.escape_json_string(input_str)
  if input_str then
    input_str = string.gsub(input_str, "\\", "\\\\") -- Escape backslashes
    input_str = string.gsub(input_str, '"', '\\"') -- Escape double quotes
    input_str = string.gsub(input_str, "\n", "\\n") -- Escape newlines
    input_str = string.gsub(input_str, "\r", "\\r") -- Escape carriage returns
    input_str = string.gsub(input_str, "\t", "\\t") -- Escape tabs
  end
  return input_str
end

return M
