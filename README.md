# Linear plugin for NeoVim

## The problem
You're working on a project where issues are managed in [Linear](https://linear.app/karma-horizons). 
You want to browse issues assigned to you, read their description and copy the git branch name, all from within 
NeoVim using keyboard shortcuts. In addition, you want to be able to quickly create issues, also from within your
editor. These are the usecases linear-nvim is designed for.

![Screen Recording 2024-05-13 at 9 11 05 AM](https://github.com/rmanocha/linear-nvim/assets/4594/e8e7d9ce-89e8-4d87-aa1d-c36479600ba3)



## Installation
* neovim 0.8.0+ required
* Install using your favorite plugin manager. I'm using lazy.nvim in this case
* You will need `nvim-lua/plenary.nvim` and `nvim-telescope/telescope.nvim` installed
   * The former is used for making http requests while the latter is used to show query results and make selections 
  
```lua
return {
  {
    "rmanocha/linear-nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("linear-nvim").setup()
    end,
  },
}
```

## Configuration
For now, only one configuration option is supported.

```lua
require("linear-nvim").setup({ issue_regex = "lin%-%d+"})
```

This `issue_regex` config is optional. It is required if you want to view issue details.
Set this to a regex that will match against the issue number format for your Linear workspace.
Once this is set, you can call `show_issue_details()` to view the details of the issue
 number under the cursor

## Usage
The following use cases are supported as of now
* Fetch issues assigned to you
  * 50 most recent issues are returned
  * You can search through them
  * You can preview the description
  * Copy the git branch name
* You can create a new issue
  * You will be prompted for the team to create the issue in (if you have multiple teams)
  * You will also be prompted to enter a title for this issue
  * Description is in the works, as soon as I can figure out how to send it successfully via the graphql API
  * After the issue is created, you can copy the identifier, git branch name, url etc.
* View issue details
  * Move your cursor to an issue number in your buffer and call `show_issue_details()` to view details about this issue.

### Getting an API Key

Only supported authentication method is using the [Linear Personal API keys](https://developers.linear.app/docs/graphql/working-with-the-graphql-api#personal-api-keys). 
You will be prompted to provide it the first time (post installation) the plugin tries to query the Linear API.

#### Storage of the API Key

We store the API key you provide in a plaintext file in `vim.fn.stdpath("data")`. You can always delete it there. Alternatively, you can simply revoke the key from Linear itself, if/when needed.

### Keymaps

You can put these wherever you define your custom keymaps (eg. `lua/config/keymaps.lua`) if you're using [LazyVim](https://github.com/LazyVim/LazyVim))

```lua
vim.keymap.set("n", "<leader>mm", function()
  require("linear-nvim").show_assigned_issues()
end)
vim.keymap.set("v", "<leader>mc", function()
  require("linear-nvim").create_issue()
end)
vim.keymap.set("n", "<leader>mc", function()
  require("linear-nvim").create_issue()
end)
```

## Roadmap

* Provide configuration options
  * Change the default behavior from copy to something else (eg. open in browser)
  * Pull more than 50 issues when trying to list them
  * Add a default tag when creating new issues
  * Filter down listed issues to a specific team
* Integrate with a git plugin to automatically create the new branch (does lazygit support this?)
* Add support to provide a description for newly created issues
* Integrate with [folke/todo-comments.nvim](https://github.com/folke/todo-comments.nvim) to create issues from TODOs
* Build a viewer to be able to see title, description etc. when hovering over a Linear issue identifier
* Add tests
