local stub = require("luassert.stub")
local assert = require("luassert")
local log = require("plenary.log")

describe("init", function()
    -- Mock all telescope dependencies before requiring linear-nvim
    package.loaded["telescope.pickers"] = {}
    package.loaded["telescope.finders"] = {}
    package.loaded["telescope.config"] = {
        values = {
            layout_config = {},
            generic_sorter = function()
                return {}
            end,
        },
    }
    package.loaded["telescope.themes"] = {
        get_dropdown = function()
            return {}
        end,
    }
    package.loaded["telescope.actions"] = {
        select_default = { replace = function() end },
        close = function() end,
    }
    package.loaded["telescope.actions.state"] = {
        get_selected_entry = function()
            return {}
        end,
    }
    package.loaded["telescope.previewers"] = {
        new_buffer_previewer = function()
            return {}
        end,
    }

    local linear = require("linear-nvim")
    local log_stub
    local client_stub

    before_each(function()
        -- Stub the log.new function
        log_stub = stub(require("plenary.log"), "new")
        -- Stub the client setup
        client_stub = stub(require("linear-nvim.client"), "setup")
    end)

    after_each(function()
        if log_stub then
            log_stub:revert()
        end
        if client_stub then
            client_stub:revert()
        end
    end)

    it("should initialize with default options when none provided", function()
        linear.setup({})

        -- Verify log was initialized with default level
        assert.stub(log_stub).was_called_with({
            plugin = "linear-nvim",
            use_console = "async",
            level = "warn",
        }, true)

        -- Verify client was initialized with default fields and labels
        assert.stub(client_stub).was_called()
        local client_call = client_stub.calls[1]
        log.warn(client_call.refs[2])
        assert.equals("function", type(client_call.vals[1]["fetch_api_key"])) -- key_store.fetch_api_key
        assert.same({
            "url",
            "branchName",
            "title",
            "identifier",
            "description",
            "id",
        }, client_call.refs[3]) -- issue_fields
        assert.same({}, client_call.refs[4]) -- default_label_ids
    end)

    it("should merge user options with defaults", function()
        linear.setup({
            issue_fields = { "url", "title" },
            log_level = "debug",
            default_label_ids = { "label1", "label2" },
        })

        -- Verify log was initialized with user level
        assert.stub(log_stub).was_called_with({
            plugin = "linear-nvim",
            use_console = "async",
            level = "debug",
        }, true)

        -- Verify client was initialized with user fields and labels
        assert.stub(client_stub).was_called()
        local client_call = client_stub.calls[1]
        assert.equals("function", type(client_call.vals[1]["fetch_api_key"])) -- key_store.fetch_api_key
        assert.same({ "url", "title" }, client_call.refs[3]) -- issue_fields
        assert.same({ "label1", "label2" }, client_call.refs[4]) -- default_label_ids
    end)
end)
