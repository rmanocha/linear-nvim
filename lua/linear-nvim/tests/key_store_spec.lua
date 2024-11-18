local mock = require("luassert.mock")
local stub = require("luassert.stub")

describe("key-store", function()
    local key_store = require("linear-nvim.key-store")
    local test_api_key = "test_key_123"
    local test_file_path = vim.fn.stdpath("data") .. "/linear_api_key.txt"

    before_each(function()
        -- Clean up any existing test file
        os.remove(test_file_path)
    end)

    after_each(function()
        -- Clean up after each test
        os.remove(test_file_path)
    end)

    it("should prompt for API key if file doesn't exist", function()
        -- Mock vim.fn.input
        local input_stub = stub(vim.fn, "input", function()
            return test_api_key
        end)

        local result = key_store.fetch_api_key()

        -- Verify input was called
        assert.stub(input_stub).was_called()
        -- Verify returned key matches input
        assert.equals(test_api_key, result)

        -- Verify key was saved to file
        local file = io.open(test_file_path, "r")
        local saved_key = file:read("*a")
        file:close()
        assert.equals(test_api_key, saved_key)

        -- Restore original input function
        input_stub:revert()
    end)

    it("should return nil if no API key is entered", function()
        -- Mock vim.fn.input to return empty string
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
        -- Create test file with API key
        local file = io.open(test_file_path, "w")
        file:write(test_api_key)
        file:close()

        -- Mock vim.fn.input to ensure it's not called
        local input_stub = stub(vim.fn, "input")

        local result = key_store.fetch_api_key()

        -- Verify input was not called
        assert.stub(input_stub).was_not_called()
        -- Verify returned key matches file content
        assert.equals(test_api_key, result)

        input_stub:revert()
    end)
end)
