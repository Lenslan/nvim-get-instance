local vim = vim
vim.cmd [[set runtimepath+=.]]
vim.cmd [[set runtimepath+=../plenary.nvim]] -- 假设 plenary 在上级目录
vim.cmd [[runtime! plugin/plenary.vim]]

-- 模拟 Tree-sitter 配置（如果是在非标准环境中）
vim.o.swapfile = false
vim.bo.swapfile = false