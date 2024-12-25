-- TODO: Move all client setup logic to before_each instead of setting up the client in each test case
local stub = require("luassert.stub")
local assert = require("luassert")

describe("linear client tests", function()
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

    local linear_client = require("linear-nvim.client")

    before_each(function()
        -- Force a complete reload of the module since linear client returns a singleton
        package.loaded["linear-nvim.client"] = nil
        linear_client = require("linear-nvim.client")
    end)

    it("should initialize the linear client with default options", function()
        local fetch_key_func = function()
            return "blah"
        end
        local client = linear_client:setup(fetch_key_func, { "id" })
        assert.same(fetch_key_func, client.callback_for_api_key)
        assert.same({ "id" }, client._issue_fields)
    end)

    it("should initialize the linear client with custom labels", function()
        local fetch_key_func = function()
            return "blah"
        end
        local client = linear_client:setup(fetch_key_func, { "id" }, { "abc" })
        assert.same(fetch_key_func, client.callback_for_api_key)
        assert.same({ "id" }, client._issue_fields)
        assert.same({ "abc" }, client._default_labels)
    end)

    it("test fetch_api_key without cached key", function()
        local fetch_key_func = stub().invokes(function()
            return "blah"
        end)
        local client = linear_client:setup(fetch_key_func, { "id" }, { "abc" })
        local ret_key = client:fetch_api_key()
        assert.same(ret_key, "blah")
        assert.stub(fetch_key_func).was_called_with()
        assert.stub(fetch_key_func).was_called(1)
    end)

    it("test fetch_api_key with cached key", function()
        local fetch_key_func = stub().invokes(function()
            return "blah"
        end)
        local client = linear_client:setup(fetch_key_func, { "id" }, { "abc" })
        local ret_key_first = client:fetch_api_key()
        local ret_key_second = client:fetch_api_key()

        assert.same(ret_key_first, "blah")
        assert.same(ret_key_second, "blah")

        assert.stub(fetch_key_func).was_called_with()
        assert.stub(fetch_key_func).was_called(1)
    end)

    it(
        "test fetch_api_key without cached key and nil from callback_for_api_key",
        function()
            local fetch_key_func = stub().invokes(function()
                return nil
            end)
            local client = linear_client:setup(
                fetch_key_func,
                { "id" },
                { "abc" }
            )
            local ret_key = client:fetch_api_key()
            assert.same(ret_key, "")
            assert.stub(fetch_key_func).was_called_with()
            assert.stub(fetch_key_func).was_called(1)

            assert.same("", client._api_key)
        end
    )

    it("test get_user_id returns user id from API", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client = linear_client:setup(fetch_key_func, { "id" })

        stub(client, "_make_query").returns({
            data = {
                viewer = {
                    id = "user-123",
                    name = "Test User",
                },
            },
        })

        local user_id = client:get_user_id()

        assert.same("user-123", user_id)
        assert
            .stub(client._make_query)
            .was_called_with("test-key", '{ "query": "{ viewer { id name } }" }')
        assert.stub(client._make_query).was_called(1)
    end)

    it("test get_user_id returns nil when API call fails", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client = linear_client:setup(fetch_key_func, { "id" })

        stub(client, "_make_query").returns(nil)

        local user_id = client:get_user_id()

        assert.is_nil(user_id)
        assert
            .stub(client._make_query)
            .was_called_with("test-key", '{ "query": "{ viewer { id name } }" }')
        assert.stub(client._make_query).was_called(1)
    end)

    it("test get_assigned_issues returns issues from API", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client = linear_client:setup(fetch_key_func, { "id" })

        -- First stub for get_user_id call
        stub(client, "get_user_id").returns("user-123")

        -- Second stub for the actual issues query
        stub(client, "_make_query").returns({
            data = {
                user = {
                    assignedIssues = {
                        nodes = {
                            {
                                id = "issue-1",
                                title = "First Issue",
                                identifier = "PROJ-1",
                                branchName = "feature/proj-1",
                                description = "Test description",
                            },
                            {
                                id = "issue-2",
                                title = "Second Issue",
                                identifier = "PROJ-2",
                                branchName = "feature/proj-2",
                                description = "Another description",
                            },
                        },
                    },
                },
            },
        })

        local issues = client:get_assigned_issues()

        assert.is_not_nil(issues)
        assert.equals(2, #issues)
        assert.same("issue-1", issues[1].id)
        assert.same("First Issue", issues[1].title)
        assert.same("issue-2", issues[2].id)
        assert.same("Second Issue", issues[2].title)

        assert.stub(client._make_query).was_called(1)
        -- Verify the query format
        assert.stub(client._make_query).was_called_with(
            "test-key",
            '{"query": "query { user(id: \\"user-123\\") { id name assignedIssues(filter: {state: {type: {nin: [\\"completed\\", \\"canceled\\"]}}}) { nodes { id title identifier branchName description } } } }"}'
        )
    end)

    it("test get_assigned_issues returns nil when API call fails", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client = linear_client:setup(fetch_key_func, { "id" })

        -- First stub for get_user_id call
        stub(client, "get_user_id").returns("user-123")

        -- Second stub for the failed query
        stub(client, "_make_query").returns(nil)

        local issues = client:get_assigned_issues()

        assert.is_nil(issues)
        assert.stub(client._make_query).was_called(1)
        -- Verify the query was attempted
        assert.stub(client._make_query).was_called_with(
            "test-key",
            '{"query": "query { user(id: \\"user-123\\") { id name assignedIssues(filter: {state: {type: {nin: [\\"completed\\", \\"canceled\\"]}}}) { nodes { id title identifier branchName description } } } }"}'
        )
    end)

    it("test get_teams returns teams from API", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client = linear_client:setup(fetch_key_func, { "id" })

        stub(client, "_make_query").returns({
            data = {
                teams = {
                    nodes = {
                        {
                            id = "team-1",
                            name = "Engineering",
                        },
                        {
                            id = "team-2",
                            name = "Design",
                        },
                    },
                },
            },
        })

        local teams = client:get_teams()

        assert.is_not_nil(teams)
        assert.equals(2, #teams)
        assert.same("team-1", teams[1].id)
        assert.same("Engineering", teams[1].name)
        assert.same("team-2", teams[2].id)
        assert.same("Design", teams[2].name)

        assert.stub(client._make_query).was_called(1)
        assert
            .stub(client._make_query)
            .was_called_with("test-key", '{ "query": "query { teams { nodes {id name }} }" }')
    end)

    it("test get_teams returns nil when API call fails", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client = linear_client:setup(fetch_key_func, { "id" })

        stub(client, "_make_query").returns(nil)

        local teams = client:get_teams()

        assert.is_nil(teams)
        assert.stub(client._make_query).was_called(1)
        assert
            .stub(client._make_query)
            .was_called_with("test-key", '{ "query": "query { teams { nodes {id name }} }" }')
    end)

    it("test get_issue_details returns issue details from API", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client =
            linear_client:setup(fetch_key_func, { "id", "title", "identifier" })

        stub(client, "_make_query").returns({
            data = {
                issue = {
                    id = "issue-123",
                    title = "Test Issue",
                    identifier = "PROJ-123",
                },
            },
        })

        local issue = client:get_issue_details("issue-123")

        assert.is_not_nil(issue)
        assert.same("issue-123", issue.id)
        assert.same("Test Issue", issue.title)
        assert.same("PROJ-123", issue.identifier)

        assert.stub(client._make_query).was_called(1)
        assert.stub(client._make_query).was_called_with(
            "test-key",
            '{"query":"query { issue(id: \\"issue-123\\") { id title identifier }}"}'
        )
    end)

    it("test get_issue_details returns nil when API call fails", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client = linear_client:setup(fetch_key_func, { "id", "title" })

        stub(client, "_make_query").returns(nil)

        local issue = client:get_issue_details("issue-123")

        assert.is_nil(issue)
        assert.stub(client._make_query).was_called(1)
        assert.stub(client._make_query).was_called_with(
            "test-key",
            '{"query":"query { issue(id: \\"issue-123\\") { id title }}"}'
        )
    end)

    it("test fetch_team_id returns cached team id", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client = linear_client:setup(fetch_key_func, { "id" })
        client._team_id = "team-cached"

        local callback_called = false
        local received_team_id = nil

        client:fetch_team_id(function(team_id)
            callback_called = true
            received_team_id = team_id
        end)

        assert.is_true(callback_called)
        assert.same("team-cached", received_team_id)
    end)

    it("test fetch_team_id auto-selects when only one team exists", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client = linear_client:setup(fetch_key_func, { "id" })

        stub(client, "get_teams").returns({
            {
                id = "single-team",
                name = "Engineering",
            },
        })

        local callback_called = false
        local received_team_id = nil

        client:fetch_team_id(function(team_id)
            callback_called = true
            received_team_id = team_id
        end)

        assert.is_true(callback_called)
        assert.same("single-team", received_team_id)
        assert.same("single-team", client._team_id)
        assert.stub(client.get_teams).was_called(1)
    end)

    it("test fetch_team_id handles API failure", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client = linear_client:setup(fetch_key_func, { "id" })

        stub(client, "get_teams").returns(nil)

        local callback_called = false
        local received_team_id = nil

        client:fetch_team_id(function(team_id)
            callback_called = true
            received_team_id = team_id
        end)

        assert.is_true(callback_called)
        assert.is_nil(received_team_id)
        assert.stub(client.get_teams).was_called(1)
    end)

    it("test fetch_team_id handles multiple teams", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client = linear_client:setup(fetch_key_func, { "id" })

        stub(client, "get_teams").returns({
            {
                id = "team-1",
                name = "Engineering",
            },
            {
                id = "team-2",
                name = "Design",
            },
        })

        -- Mock vim.ui.select
        local original_select = vim.ui.select
        vim.ui.select = function(items, opts, on_choice)
            -- Simulate user selecting the first team
            on_choice(items[1])
        end

        local callback_called = false
        local received_team_id = nil

        client:fetch_team_id(function(team_id)
            callback_called = true
            received_team_id = team_id
        end)

        -- Restore original vim.ui.select
        vim.ui.select = original_select

        assert.is_true(callback_called)
        assert.same("team-1", received_team_id)
        assert.same("team-1", client._team_id)
        assert.stub(client.get_teams).was_called(1)
    end)

    it("test fetch_team_id handles cancelled team selection", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client = linear_client:setup(fetch_key_func, { "id" })

        stub(client, "get_teams").returns({
            {
                id = "team-1",
                name = "Engineering",
            },
            {
                id = "team-2",
                name = "Design",
            },
        })

        -- Mock vim.ui.select to simulate user cancellation
        local original_select = vim.ui.select
        vim.ui.select = function(items, opts, on_choice)
            -- Simulate user cancelling the selection
            on_choice(nil)
        end

        local callback_called = false
        local received_team_id = nil

        client:fetch_team_id(function(team_id)
            callback_called = true
            received_team_id = team_id
        end)

        -- Restore original vim.ui.select
        vim.ui.select = original_select

        assert.is_true(callback_called)
        assert.is_nil(received_team_id)
        assert.same("", client._team_id) -- Team ID should not be set
        assert.stub(client.get_teams).was_called(1)
    end)

    it("test create_issue successfully creates an issue", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client = linear_client:setup(
            fetch_key_func,
            { "id", "title" },
            { "label1" }
        )

        -- Stub dependencies
        stub(client, "get_user_id").returns("user-123")
        client._team_id = "team-456" -- Pre-set team ID to avoid selection flow

        stub(client, "_make_query").returns({
            data = {
                issueCreate = {
                    success = true,
                    issue = {
                        id = "issue-789",
                        title = "Test Issue",
                    },
                },
            },
        })

        local callback_called = false
        local received_issue = nil

        client:create_issue("Test Issue", "Test Description", function(issue)
            callback_called = true
            received_issue = issue
        end)

        assert.is_true(callback_called)
        assert.is_not_nil(received_issue)
        assert.same("issue-789", received_issue.id)
        assert.same("Test Issue", received_issue.title)

        -- Verify the mutation query
        assert.stub(client._make_query).was_called(1)
        assert.stub(client._make_query).was_called_with(
            "test-key",
            '{"query": "mutation IssueCreate { issueCreate(input: {title: \\"Test Issue\\" teamId: \\"team-456\\" assigneeId: \\"user-123\\" labelIds: [\\"label1\\"]}) { success issue { id title } } }"}'
        )
    end)

    it("test create_issue handles user ID fetch failure", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client = linear_client:setup(fetch_key_func, { "id" })

        stub(client, "get_user_id").returns(nil)
        stub(client, "_make_query").returns(nil)

        local callback_called = false
        local received_issue = nil

        client:create_issue("Test Issue", "Test Description", function(issue)
            callback_called = true
            received_issue = issue
        end)

        assert.is_true(callback_called)
        assert.is_nil(received_issue)
        assert.stub(client.get_user_id).was_called(1)
        -- Verify _make_query was never called
        assert.stub(client._make_query).was_not_called()
    end)

    it("test create_issue handles team ID fetch failure", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client = linear_client:setup(fetch_key_func, { "id" })

        stub(client, "get_user_id").returns("user-123")
        stub(client, "get_teams").returns(nil) -- This will cause team ID fetch to fail

        local callback_called = false
        local received_issue = nil

        client:create_issue("Test Issue", "Test Description", function(issue)
            callback_called = true
            received_issue = issue
        end)

        assert.is_true(callback_called)
        assert.is_nil(received_issue)
        assert.stub(client.get_user_id).was_called(1)
        assert.stub(client.get_teams).was_called(1)
    end)

    it("test create_issue handles API call failure", function()
        local fetch_key_func = function()
            return "test-key"
        end
        local client = linear_client:setup(fetch_key_func, { "id" })

        stub(client, "get_user_id").returns("user-123")
        client._team_id = "team-456" -- Pre-set team ID to avoid selection flow

        stub(client, "_make_query").returns({
            data = {
                issueCreate = {
                    success = false,
                },
            },
        })

        local callback_called = false
        local received_issue = nil

        client:create_issue("Test Issue", "Test Description", function(issue)
            callback_called = true
            received_issue = issue
        end)

        assert.is_true(callback_called)
        assert.is_nil(received_issue)
        assert.stub(client._make_query).was_called(1)
    end)
end)
