-- init.lua - 插件入口和主要功能
local M = {}

local config = require('verilog-hierarchy.config')
local parser = require('verilog-hierarchy.parser')
local ui = require('verilog-hierarchy.ui')
local navigator = require('verilog-hierarchy.navigator')

-- 初始化插件
-- @param opts table: 用户配置选项
function M.setup(opts)
  config.setup(opts)
  
  -- 注册命令
  vim.api.nvim_create_user_command('VerilogHierarchy', function()
    M.show_hierarchy()
  end, { desc = 'Show Verilog module hierarchy' })
  
  vim.api.nvim_create_user_command('VerilogJumpDef', function()
    M.jump_to_definition()
  end, { desc = 'Jump to Verilog module definition' })
  
  -- 设置快捷键
  local keymaps = config.get('keymaps')
  if keymaps.show_hierarchy then
    vim.keymap.set('n', keymaps.show_hierarchy, M.show_hierarchy, 
      { desc = 'Show Verilog hierarchy', silent = true })
  end
  if keymaps.jump_to_def then
    vim.keymap.set('n', keymaps.jump_to_def, M.jump_to_definition,
      { desc = 'Jump to Verilog definition', silent = true })
  end
end

-- 显示当前模块的层级关系
function M.show_hierarchy()
  local bufnr = vim.api.nvim_get_current_buf()
  
  -- 解析例化
  local instantiations, err = parser.parse_instantiations(bufnr)
  
  if err then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  
  if not instantiations or #instantiations == 0 then
    vim.notify("No module instantiations found in current file", vim.log.levels.INFO)
    return
  end
  
  -- 显示浮动窗口
  ui.show_hierarchy(instantiations, function(inst)
    -- 关闭窗口
    ui.close_window()
    
    -- 跳转到例化位置
    navigator.jump_to_location(inst.line, inst.col)
  end)
end

-- 跳转到模块定义
function M.jump_to_definition()
  -- 获取光标下的单词
  local word = vim.fn.expand('<cword>')
  
  if not word or word == '' then
    vim.notify("No word under cursor", vim.log.levels.WARN)
    return
  end
  
  -- 尝试使用 LSP 跳转
  local success = navigator.jump_to_definition(word)
  
  if not success then
    -- 回退方法：在项目中搜索模块定义
    vim.notify("Searching for module definition: " .. word, vim.log.levels.INFO)
    vim.cmd('vimgrep /\\<module\\s\\+' .. word .. '\\>/gj **/*.v **/*.sv')
    vim.cmd('copen')
  end
end

return M
