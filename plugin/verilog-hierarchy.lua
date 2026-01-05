-- plugin/verilog-hierarchy.lua - 插件自动加载入口

-- 防止重复加载
if vim.g.loaded_verilog_hierarchy then
  return
end
vim.g.loaded_verilog_hierarchy = 1

-- 插件会在用户调用 setup() 时初始化
-- 这里只是确保插件被 Neovim 识别
