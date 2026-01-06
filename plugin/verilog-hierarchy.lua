-- Plugin entry point
-- This file is automatically loaded by Neovim when the plugin is installed

if vim.fn.has("nvim-0.8.0") == 0 then
  vim.api.nvim_err_writeln("verilog-hierarchy requires Neovim >= 0.8.0")
  return
end

-- Prevent loading the plugin twice
if vim.g.loaded_verilog_hierarchy then
  return
end
vim.g.loaded_verilog_hierarchy = 1

-- The plugin will be set up by the user calling require("verilog-hierarchy").setup()
