-- config.lua - 配置管理模块
local M = {}

-- 默认配置
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

-- 当前配置
M.options = vim.deepcopy(M.defaults)

-- 深度合并两个表
local function deep_merge(target, source)
  for key, value in pairs(source) do
    if type(value) == 'table' and type(target[key]) == 'table' then
      deep_merge(target[key], value)
    else
      target[key] = value
    end
  end
  return target
end

-- 设置用户配置
-- @param opts table: 用户配置选项
function M.setup(opts)
  opts = opts or {}
  M.options = deep_merge(vim.deepcopy(M.defaults), opts)
end

-- 获取配置值
-- @param key string: 配置键（支持点号分隔的路径）
-- @return any: 配置值
function M.get(key)
  local keys = vim.split(key, '.', { plain = true })
  local value = M.options
  
  for _, k in ipairs(keys) do
    if type(value) ~= 'table' then
      return nil
    end
    value = value[k]
  end
  
  return value
end

return M
