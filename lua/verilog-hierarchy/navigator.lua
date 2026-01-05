-- navigator.lua - 跳转和导航逻辑模块
local M = {}

-- 检查 LSP 是否可用
-- @return boolean: LSP 是否已连接
function M.is_lsp_available()
  local clients = vim.lsp.get_active_clients()
  return #clients > 0
end

-- 跳转到指定行和列
-- @param line number: 目标行号（1-based）
-- @param col number: 目标列号（0-based）
function M.jump_to_location(line, col)
  -- 验证行号是否有效
  local total_lines = vim.api.nvim_buf_line_count(0)
  if line < 1 or line > total_lines then
    vim.notify("Target location not found", vim.log.levels.ERROR)
    return false
  end
  
  -- 跳转到位置
  vim.api.nvim_win_set_cursor(0, {line, col})
  
  -- 将目标行居中显示
  vim.cmd('normal! zz')
  
  return true
end

-- 使用 LSP 跳转到模块定义
-- @param module_type string: 模块类型名称
-- @return boolean: 是否成功跳转
function M.jump_to_definition(module_type)
  if not M.is_lsp_available() then
    vim.notify("LSP not available", vim.log.levels.WARN)
    return false
  end
  
  -- 保存当前位置
  local current_pos = vim.api.nvim_win_get_cursor(0)
  
  -- 使用 LSP 的 textDocument/definition 请求
  local params = vim.lsp.util.make_position_params()
  
  local timeout = 5000  -- 5 秒超时
  local result = nil
  local completed = false
  
  vim.lsp.buf_request(0, 'textDocument/definition', params, function(err, response)
    completed = true
    if err then
      vim.notify("LSP error: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    result = response
  end)
  
  -- 等待响应或超时
  local start_time = vim.loop.now()
  while not completed and (vim.loop.now() - start_time) < timeout do
    vim.wait(10)
  end
  
  if not completed then
    vim.notify("LSP timeout, using fallback navigation", vim.log.levels.WARN)
    return false
  end
  
  if result and #result > 0 then
    -- 跳转到第一个定义位置
    vim.lsp.util.jump_to_location(result[1], 'utf-8')
    return true
  end
  
  return false
end

return M
