local M = {}

M.defaults = {
  -- 快捷键配置
  keymaps = {
    show_hierarchy = '<leader>vh',  -- 显示层级
    jump_to_def = '<leader>vd',     -- 跳转到定义
  },
  
  -- UI 配置
  ui = {
    window_type = 'float',  -- 'float' 或 'split'
    width_ratio = 0.6,      -- 浮动窗口宽度比例
    height_ratio = 0.5,     -- 浮动窗口高度比例
    border = 'rounded',     -- 边框样式
  },
  
  -- 解析器配置
  parser = {
    use_treesitter = true,  -- 优先使用 Tree-sitter
    fallback_regex = true,  -- 启用正则表达式回退
  },
}

M.options = {}

-- 设置用户配置
-- @param opts table: 用户配置选项
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

-- 获取配置值
-- @param key string: 配置键（支持点号分隔的路径，如 "ui.border"）
-- @return any: 配置值
function M.get(key)
  local keys = vim.split(key, "%.")
  local val = M.options
  
  for _, k in ipairs(keys) do
    if val[k] == nil then return nil end
    val = val[k]
  end
  
  return val
end

return M