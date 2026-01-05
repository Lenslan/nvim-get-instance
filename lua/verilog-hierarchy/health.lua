-- health.lua - 健康检查模块
-- 用于 :checkhealth verilog-hierarchy

local M = {}

local health = vim.health or require('health')
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

function M.check()
  start('Verilog Hierarchy Navigator')
  
  -- 检查 Neovim 版本
  local nvim_version = vim.version()
  if nvim_version.major == 0 and nvim_version.minor < 8 then
    error('Neovim >= 0.8.0 is required')
  else
    ok(string.format('Neovim version: %d.%d.%d', 
      nvim_version.major, nvim_version.minor, nvim_version.patch))
  end
  
  -- 检查插件是否正确加载
  local plugin_ok, _ = pcall(require, 'verilog-hierarchy')
  if plugin_ok then
    ok('Plugin loaded successfully')
  else
    error('Failed to load plugin')
    return
  end
  
  -- 检查配置模块
  local config_ok, config = pcall(require, 'verilog-hierarchy.config')
  if config_ok then
    ok('Config module loaded')
    info('Window type: ' .. (config.get('ui.window_type') or 'unknown'))
    info('Border style: ' .. (config.get('ui.border') or 'unknown'))
  else
    error('Failed to load config module')
  end
  
  -- 检查 Tree-sitter
  start('Tree-sitter')
  local ts_ok, _ = pcall(require, 'nvim-treesitter')
  if ts_ok then
    ok('nvim-treesitter is installed')
    
    -- 检查 Verilog parser
    local parser_ok = pcall(vim.treesitter.get_parser, 0, 'verilog')
    if parser_ok then
      ok('Verilog parser is installed')
    else
      warn('Verilog parser not found. Run :TSInstall verilog')
      info('Plugin will use fallback regex parser')
    end
  else
    warn('nvim-treesitter is not installed')
    info('Plugin will use fallback regex parser')
    info('Install nvim-treesitter for better parsing accuracy')
  end
  
  -- 检查 LSP
  start('LSP')
  local clients = vim.lsp.get_active_clients()
  if #clients > 0 then
    ok('LSP clients found: ' .. #clients)
    for _, client in ipairs(clients) do
      if client.name:match('verilog') or client.name:match('verible') or client.name:match('svls') then
        ok('Verilog LSP found: ' .. client.name)
      end
    end
  else
    warn('No LSP clients active')
    info('Install a Verilog LSP server for better navigation')
    info('Recommended: verible-verilog-ls or svls')
  end
  
  -- 检查命令
  start('Commands')
  local commands = vim.api.nvim_get_commands({})
  if commands['VerilogHierarchy'] then
    ok('VerilogHierarchy command registered')
  else
    error('VerilogHierarchy command not found')
  end
  
  if commands['VerilogJumpDef'] then
    ok('VerilogJumpDef command registered')
  else
    error('VerilogJumpDef command not found')
  end
  
  -- 检查快捷键
  start('Keymaps')
  local config_ok2, config2 = pcall(require, 'verilog-hierarchy.config')
  if config_ok2 then
    local show_key = config2.get('keymaps.show_hierarchy')
    local jump_key = config2.get('keymaps.jump_to_def')
    
    if show_key then
      info('Show hierarchy keymap: ' .. show_key)
    end
    if jump_key then
      info('Jump to definition keymap: ' .. jump_key)
    end
  end
  
  -- 检查文件类型
  start('File Types')
  local ft = vim.api.nvim_buf_get_option(0, 'filetype')
  if ft == 'verilog' or ft == 'systemverilog' then
    ok('Current file is Verilog: ' .. ft)
  else
    info('Current file is not Verilog (filetype: ' .. ft .. ')')
    info('Plugin works with verilog and systemverilog filetypes')
  end
end

return M
