# Linear plugin for NeoVim

## Installation
* neovim 0.8.0+ required
* Install using your favorite plugin manager. I'm using lazy.nvim in this case
* You will need `nvim-lua/plenary.nvim` and `nvim-telescope/telescope.nvim` installed
   * The former is used for making http requests while the latter is used to show query results and make selections 
  
```lua
return {
  {
    dir = "~/dev/linear-nvim",
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
TBD

## Usage
There are only two primary use cases supported as of now
* You can fetch the 50 most recent issues assigned to you, search through the title/identifier of each of them, read it's description and copy the git branch of any one
* You can create a new issue - only providing a title is supported as of now
  * Description is in the works, as soon as I can figure out how to send it successfully via the graphql API 

### Getting an API Key

Only supported authentication method is using the [Linear Personal API keys](https://developers.linear.app/docs/graphql/working-with-the-graphql-api#personal-api-keys). 
You will be prompted to provide it the first time (post installation) the plugin tries to query the Linear API.

#### Storage of the API Key

We store the API key you provide in a plaintext file in `vim.fn.stdpath("data")`. You can always delete it there. Alternatively, you can simply revoke the key from Linear itself, if/when needed.

### Keymaps

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
