local M = {}
local config = require('verilog-hierarchy.config')
local api = vim.api

local win_id = nil
local buf_id = nil

-- 关闭浮动窗口
function M.close_window()
  if win_id and api.nvim_win_is_valid(win_id) then
    api.nvim_win_close(win_id, true)
  end
  win_id = nil
  buf_id = nil
end

-- 设置窗口键盘映射
function M.setup_keymaps(bufnr, on_select, instantiations)
  local opts = { noremap = true, silent = true, buffer = bufnr }
  
  -- 选择 (Enter)
  vim.keymap.set('n', '<CR>', function()
    local cursor = api.nvim_win_get_cursor(0)
    local idx = cursor[1]
    local item = instantiations[idx]
    if item then
      M.close_window()
      on_select(item)
    end
  end, opts)
  
  -- 关闭 (q, ESC)
  vim.keymap.set('n', 'q', M.close_window, opts)
  vim.keymap.set('n', '<Esc>', M.close_window, opts)
end

-- 创建并显示浮动窗口
function M.show_hierarchy(instantiations, on_select)
  if #instantiations == 0 then
    vim.notify("No module instantiations found.", vim.log.levels.INFO)
    return
  end

  -- 创建缓冲区
  buf_id = api.nvim_create_buf(false, true)
  
  -- 准备显示内容
  local lines = {}
  local max_width = 0
  for _, item in ipairs(instantiations) do
    local line_str = string.format("[%d] %s %s", item.line, item.module_type, item.instance_name)
    if item.has_params then
       line_str = line_str .. " (P)"
    end
    table.insert(lines, line_str)
    if #line_str > max_width then max_width = #line_str end
  end
  
  api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
  
  -- 计算窗口尺寸
  local width_ratio = config.get('ui.width_ratio')
  local height_ratio = config.get('ui.height_ratio')
  local width = math.floor(vim.o.columns * width_ratio)
  local height = math.min(#lines, math.floor(vim.o.lines * height_ratio))
  
  -- 窗口配置
  local win_opts = {
    relative = 'editor',
    width = math.max(width, max_width + 4),
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = config.get('ui.border'),
    title = ' Module Instantiations ',
    title_pos = 'center'
  }
  
  -- 创建窗口
  win_id = api.nvim_open_win(buf_id, true, win_opts)
  
  -- 设置高亮和选项
  api.nvim_buf_set_option(buf_id, 'filetype', 'verilog-hierarchy')
  api.nvim_buf_set_option(buf_id, 'cursorline', true)
  api.nvim_buf_set_option(buf_id, 'modifiable', false)
  
  M.setup_keymaps(buf_id, on_select, instantiations)
  
  return win_id, buf_id
end

return M