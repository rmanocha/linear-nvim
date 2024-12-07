local stub = require("luassert.stub")
local assert = require("luassert")

describe("key-store", function()
    local key_store = require("linear-nvim.key-store")
    local test_api_key = "test_key_123"
    local mock_file_content = nil
    local io_open_stub

    -- Mock the plenary log
    local log_stub

    local function create_mock_file(content)
        return {
            read = function()
                return content
            end,
            write = function(_, data)
                mock_file_content = data
            end,
            close = function() end,
        }
    end

    before_each(function()
        mock_file_content = nil
        io_open_stub = stub(io, "open")
        -- Create a stub for the log.warn function
        log_stub = stub(require("plenary.log"), "warn")
    end)

    after_each(function()
        io_open_stub:revert()
        if log_stub then
            log_stub:revert()
        end
    end)

    it("should prompt for API key if file doesn't exist", function()
        -- Setup mocks
        io_open_stub
            .on_call_with(vim.fn.stdpath("data") .. "/linear_api_key.txt", "r")
            .returns(nil) -- File doesn't exist
        io_open_stub
            .on_call_with(vim.fn.stdpath("data") .. "/linear_api_key.txt", "w")
            .returns(create_mock_file())

        local input_stub = stub(vim.fn, "input", function()
            return test_api_key
        end)

        local result = key_store.fetch_api_key()

        -- Verify input was called
        assert.stub(input_stub).was_called()
        -- Verify returned key matches input
        assert.equals(test_api_key, result)
        -- Verify key was saved
        assert.equals(test_api_key, mock_file_content)

        input_stub:revert()
    end)

    it("should return nil if no API key is entered", function()
        -- Setup mocks
        io_open_stub
            .on_call_with(vim.fn.stdpath("data") .. "/linear_api_key.txt", "r")
            .returns(nil) -- File doesn't exist
        io_open_stub
            .on_call_with(vim.fn.stdpath("data") .. "/linear_api_key.txt", "w")
            .returns(create_mock_file())

        local input_stub = stub(vim.fn, "input", function()
            return ""
        end)

        local result = key_store.fetch_api_key()

        -- Verify input was called
        assert.stub(input_stub).was_called()
        -- Verify nil is returned
        assert.is_nil(result)

        input_stub:revert()
    end)

    it("should read API key from file if it exists", function()
        -- Setup mocks
        io_open_stub
            .on_call_with(vim.fn.stdpath("data") .. "/linear_api_key.txt", "r")
            .returns(create_mock_file(test_api_key))

        local input_stub = stub(vim.fn, "input")

        local result = key_store.fetch_api_key()

        -- Verify input was not called
        assert.stub(input_stub).was_not_called()
        -- Verify returned key matches file content
        assert.equals(test_api_key, result)

        input_stub:revert()
    end)
end)
