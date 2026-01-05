-- ui.lua - 浮动窗口和用户界面模块
local M = {}

-- 当前窗口和缓冲区 ID
M.win_id = nil
M.buf_id = nil

-- 格式化例化项为显示字符串
-- @param inst table: 例化信息 {module_type, instance_name, line, col}
-- @return string: 格式化的字符串
local function format_instantiation(inst)
  return string.format("[%d] %s %s", inst.line, inst.module_type, inst.instance_name)
end

-- 创建浮动窗口缓冲区
-- @param instantiations table: 例化信息列表
-- @return number: 缓冲区 ID
local function create_buffer(instantiations)
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- 设置缓冲区选项
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'verilog-hierarchy')
  
  -- 格式化并设置内容
  local lines = {}
  for _, inst in ipairs(instantiations) do
    table.insert(lines, format_instantiation(inst))
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  return buf
end

-- 关闭浮动窗口
function M.close_window()
  if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
    vim.api.nvim_win_close(M.win_id, true)
  end
  M.win_id = nil
  M.buf_id = nil
end

-- 设置窗口键盘映射
-- @param bufnr number: 缓冲区编号
-- @param instantiations table: 例化信息列表
-- @param on_select function: 选择回调函数
local function setup_keymaps(bufnr, instantiations, on_select)
  local opts = { noremap = true, silent = true, buffer = bufnr }
  
  -- 选择当前项
  vim.keymap.set('n', '<CR>', function()
    local line = vim.api.nvim_win_get_cursor(M.win_id)[1]
    if line <= #instantiations then
      on_select(instantiations[line])
    end
  end, opts)
  
  -- 关闭窗口
  vim.keymap.set('n', 'q', M.close_window, opts)
  vim.keymap.set('n', '<Esc>', M.close_window, opts)
end

-- 创建并显示浮动窗口
-- @param instantiations table: 例化信息列表
-- @param on_select function: 选择回调函数
-- @return number, number: 窗口 ID 和缓冲区 ID
function M.show_hierarchy(instantiations, on_select)
  if not instantiations or #instantiations == 0 then
    vim.notify("No module instantiations found in current file", vim.log.levels.INFO)
    return nil, nil
  end
  
  -- 关闭已存在的窗口
  M.close_window()
  
  -- 创建缓冲区
  local buf = create_buffer(instantiations)
  M.buf_id = buf
  
  -- 获取配置
  local config = require('verilog-hierarchy.config')
  local width_ratio = config.get('ui.width_ratio') or 0.6
  local height_ratio = config.get('ui.height_ratio') or 0.5
  local border = config.get('ui.border') or 'rounded'
  
  -- 计算窗口大小和位置
  local width = math.floor(vim.o.columns * width_ratio)
  local height = math.min(#instantiations + 2, math.floor(vim.o.lines * height_ratio))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  -- 窗口配置
  local win_config = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = border,
    title = ' Module Instantiations ',
    title_pos = 'center',
  }
  
  -- 创建窗口
  local ok, win = pcall(vim.api.nvim_open_win, buf, true, win_config)
  if not ok then
    vim.notify("Failed to create floating window", vim.log.levels.ERROR)
    return nil, nil
  end
  
  M.win_id = win
  
  -- 设置窗口选项
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  vim.api.nvim_win_set_option(win, 'number', false)
  vim.api.nvim_win_set_option(win, 'relativenumber', false)
  
  -- 设置键盘映射
  setup_keymaps(buf, instantiations, on_select)
  
  -- 设置光标到第一行
  vim.api.nvim_win_set_cursor(win, {1, 0})
  
  return win, buf
end

return M
