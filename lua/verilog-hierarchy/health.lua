local M = {}

function M.check()
  local health = vim.health or require("health")
  local start = health.start or health.report_start
  local ok = health.ok or health.report_ok
  local warn = health.warn or health.report_warn
  local error = health.error or health.report_error

  start("verilog-hierarchy")

  -- Check Neovim version
  local nvim_version = vim.version()
  if nvim_version.major == 0 and nvim_version.minor < 8 then
    error("Neovim >= 0.8.0 is required")
  else
    ok(string.format("Neovim version %d.%d.%d", nvim_version.major, nvim_version.minor, nvim_version.patch))
  end

  -- Check treesitter (optional but recommended for fallback)
  local has_treesitter, _ = pcall(require, "nvim-treesitter")
  if has_treesitter then
    ok("nvim-treesitter is installed")

    -- Check for Verilog parser
    local parsers = require("nvim-treesitter.parsers")
    local has_parser = parsers.has_parser("verilog")

    if has_parser then
      ok("Verilog treesitter parser is installed (used as fallback)")
    else
      warn("Verilog treesitter parser is not installed. Run :TSInstall verilog for fallback support")
    end
  else
    warn("nvim-treesitter is not installed. LSP will be used exclusively (fallback unavailable)")
  end

  -- Check for LSP support
  local has_lsp = vim.lsp ~= nil
  if has_lsp then
    ok("LSP support is available")

    -- Check if any Verilog LSP client is configured
    local bufnr = vim.api.nvim_get_current_buf()
    local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

    if filetype == "verilog" or filetype == "systemverilog" then
      local clients = vim.lsp.get_clients({ bufnr = bufnr })
      local found_verilog_lsp = false

      for _, client in ipairs(clients) do
        if client.server_capabilities.documentSymbolProvider then
          ok(string.format("LSP client '%s' with documentSymbol support is active", client.name))
          found_verilog_lsp = true
        end
      end

      if not found_verilog_lsp then
        warn("No LSP client with documentSymbol support found for current buffer")
        warn("Consider installing: svls, verible-verilog-ls, or hdl_checker")
      end
    else
      warn("Not in a Verilog buffer. Open a .v or .sv file to check LSP status")
    end
  else
    error("LSP support not available in this Neovim build")
  end

  -- Check plugin is loaded
  if vim.g.loaded_verilog_hierarchy then
    ok("Plugin is loaded")
  else
    warn("Plugin not loaded. Make sure to call require('verilog-hierarchy').setup()")
  end
end

return M
