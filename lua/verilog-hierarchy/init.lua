local config = require("verilog-hierarchy.config")
local navigator = require("verilog-hierarchy.navigator")

local M = {}

M.setup = function(opts)
  -- Setup configuration
  config.setup(opts)

  -- Create user commands
  vim.api.nvim_create_user_command("VerilogHierarchyToggle", function()
    navigator.toggle()
  end, { desc = "Toggle Verilog hierarchy window" })

  vim.api.nvim_create_user_command("VerilogHierarchyOpen", function()
    navigator.open()
  end, { desc = "Open Verilog hierarchy window" })

  vim.api.nvim_create_user_command("VerilogHierarchyClose", function()
    navigator.close()
  end, { desc = "Close Verilog hierarchy window" })

  vim.api.nvim_create_user_command("VerilogHierarchyRefresh", function()
    navigator.refresh()
  end, { desc = "Refresh Verilog hierarchy window" })

  -- Set up keybinding for toggle
  local toggle_key = config.options.keybindings.toggle
  if toggle_key and toggle_key ~= "" then
    vim.keymap.set("n", toggle_key, function()
      navigator.toggle()
    end, { noremap = true, silent = true, desc = "Toggle Verilog hierarchy" })
  end

  -- Auto-refresh on buffer write (optional)
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = { "*.v", "*.vh", "*.sv", "*.svh" },
    callback = function()
      navigator.refresh()
    end,
    desc = "Auto-refresh Verilog hierarchy on save",
  })
end

-- Export navigator functions
M.toggle = navigator.toggle
M.open = navigator.open
M.close = navigator.close
M.refresh = navigator.refresh

return M
