-- 最小化测试初始化配置
-- 用于运行测试时加载必要的插件

-- 设置 runtimepath
local plenary_dir = vim.fn.stdpath('data') .. '/site/pack/packer/start/plenary.nvim'
local plugin_dir = vim.fn.getcwd()

vim.opt.runtimepath:append(plenary_dir)
vim.opt.runtimepath:append(plugin_dir)

-- 加载 plenary
vim.cmd('runtime plugin/plenary.vim')

-- 设置测试环境
vim.opt.swapfile = false
vim.opt.hidden = true
