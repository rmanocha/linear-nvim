-- Using `M` is a common Lua convention, `M` stand for module
-- It's used for a table that contains all exported functions and properties
-- (Exported because it's returned at the end of the file)
local M = {}

function M.do_something()
  print("Hello world")
end

return M
