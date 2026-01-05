local M = {}
local config = require('verilog-hierarchy.config')
local parser = require('verilog-hierarchy.parser')
local ui = require('verilog-hierarchy.ui')
local navigator = require('verilog-hierarchy.navigator')

function M.setup(opts)
  config.setup(opts)
  
  -- 注册命令
  vim.api.nvim_create_user_command('VerilogHierarchy', function()
    M.show_hierarchy()
  end, {})
  
  -- 设置快捷键
  local keys = config.get('keymaps')
  if keys.show_hierarchy then
    vim.keymap.set('n', keys.show_hierarchy, M.show_hierarchy, { desc = "Show Verilog Hierarchy" })
  end
  if keys.jump_to_def then
    vim.keymap.set('n', keys.jump_to_def, M.jump_to_definition, { desc = "Jump to Verilog Definition" })
  end
end

function M.show_hierarchy()
  local bufnr = vim.api.nvim_get_current_buf()
  local instantiations = parser.parse_instantiations(bufnr)
  
  ui.show_hierarchy(instantiations, function(item)
    navigator.jump_to_location(item.line, item.col)
  end)
end

function M.jump_to_definition()
  -- 这是一个快捷方式，假设用户已经将光标放在模块名上
  -- 或者在层级视图跳转后使用
  navigator.jump_to_definition()
end

return M