-- Minimal init.lua for running tests
vim.cmd([[set runtimepath=$VIMRUNTIME]])
vim.cmd([[set packpath=/tmp/nvim/site]])

-- Add the plugin development directory to runtimepath
local package_root = '/tmp/nvim/site/pack'
local install_path = package_root .. '/packer/start/packer.nvim'

-- Add the plugin and its dependencies to the runtimepath
local plugin_path = vim.fn.expand('$PWD')
vim.opt.runtimepath:append(plugin_path)
vim.opt.runtimepath:append('/home/runner/.local/share/nvim/site/pack/vendor/start/plenary.nvim')
vim.opt.runtimepath:append('/home/runner/.local/share/nvim/site/pack/vendor/start/telescope.nvim')
