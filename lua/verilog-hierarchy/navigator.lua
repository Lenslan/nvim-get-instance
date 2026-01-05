local M = {}

-- 跳转到指定行和列
function M.jump_to_location(line, col)
  -- 确保行号在有效范围内
  local total_lines = vim.api.nvim_buf_line_count(0)
  if line > total_lines then
    vim.notify("Target location out of bounds", vim.log.levels.ERROR)
    return
  end
  
  vim.cmd("normal! m'") -- 添加到跳转列表
  vim.api.nvim_win_set_cursor(0, {line, col})
  vim.cmd("normal! zz") -- 居中显示
end

-- 检查 LSP 是否可用
function M.is_lsp_available()
  local clients = vim.lsp.get_active_clients({ bufnr = 0 })
  return #clients > 0
end

-- 使用 LSP 跳转到模块定义
-- 注意：这通常需要光标在模块名上，或者我们手动构建请求
-- 这里的实现逻辑是：先跳到例化处，然后尝试对模块类型执行 "go to definition"
function M.jump_to_definition(module_type)
  if not M.is_lsp_available() then
    vim.notify("LSP not available for jump to definition", vim.log.levels.WARN)
    return false
  end

  -- 构建 textDocument/definition 请求
  -- 这是一个简化的实现，依赖于当前光标已经在模块名上
  -- 在实际使用中，流程通常是：
  -- 1. 用户在列表中选择 -> jump_to_location (光标移到例化行)
  -- 2. 用户再次按键 -> jump_to_definition (对光标下的符号查找定义)
  
  local params = vim.lsp.util.make_position_params()
  
  vim.lsp.buf_request(0, 'textDocument/definition', params, function(err, result, ctx, config)
    if err then
      vim.notify("LSP error: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    
    if not result or vim.tbl_isempty(result) then
      vim.notify("Definition not found via LSP", vim.log.levels.WARN)
      return
    end
    
    if vim.islist(result) then
      vim.lsp.util.jump_to_location(result[1], 'utf-8')
    else
      vim.lsp.util.jump_to_location(result, 'utf-8')
    end
  end)
  
  return true
end

return M