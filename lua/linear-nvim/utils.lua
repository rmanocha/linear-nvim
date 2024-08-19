-- telescope imports
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local log = require("plenary.log")

local M = {}

local function tbl_length(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

-- copied from https://github.com/ibhagwan/fzf-lua/blob/64f6eff4702c23c4de5320ed668343af1e4d679e/lua/fzf-lua/utils.lua#L707-L743
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
        -- _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
        -- _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
        return ""
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

-- @param entries table {display = string, value = string, ordinal = string, description = string}
-- @param prompt_title string
function M.show_telescope_picker(entries, prompt_title)
    pickers
        .new({}, {
            prompt_title = prompt_title,
            finder = finders.new_table({
                results = entries,
                entry_maker = function(entry)
                    return {
                        value = entry.value,
                        display = entry.display,
                        ordinal = entry.ordinal,
                        description = entry.description,
                    }
                end,
            }),
            sorter = conf.generic_sorter({}),
            previewer = previewers.new_buffer_previewer({
                define_preview = function(self, entry, _)
                    local lines =
                        vim.split(entry.description, "\n", { plain = true })
                    vim.api.nvim_buf_set_lines(
                        self.state.bufnr,
                        0,
                        -1,
                        false,
                        lines
                    )
                end,
            }),
            attach_mappings = function(prompt_bufnr, _)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    vim.fn.setreg("+", selection.value) -- Copy to clipboard (system clipboard "+")
                    vim.fn.setreg('"', selection.value) -- Copy to default register (unnamed register)
                    log.debug("Copied to clipboard: " .. selection.value)
                end)
                return true
            end,
        })
        :find()
end

function M.get_current_word()
    return vim.fn.expand("<cWORD>")
end

return M
