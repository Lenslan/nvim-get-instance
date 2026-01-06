-- Debug script to inspect LSP symbols
-- Run this in Neovim with :luafile scripts/debug_lsp_symbols.lua

local function inspect_lsp_symbols()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

  print("=== LSP Symbol Inspector ===")
  print("Buffer: " .. bufnr)
  print("Filetype: " .. filetype)
  print("")

  if filetype ~= "verilog" and filetype ~= "systemverilog" then
    print("ERROR: Not a Verilog file!")
    return
  end

  -- Get LSP clients
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  if vim.tbl_isempty(clients) then
    print("ERROR: No LSP clients attached to this buffer")
    print("Make sure you have a Verilog LSP server installed and configured:")
    print("  - svls (SystemVerilog Language Server)")
    print("  - verible-verilog-ls")
    print("  - hdl_checker")
    return
  end

  print("Found " .. #clients .. " LSP client(s):")
  for _, client in ipairs(clients) do
    print("  - " .. client.name)
    print("    documentSymbol: " .. tostring(client.server_capabilities.documentSymbolProvider))
  end
  print("")

  -- Request document symbols
  local client = clients[1]
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr)
  }

  print("Requesting documentSymbol from " .. client.name .. "...")
  print("")

  client.request("textDocument/documentSymbol", params, function(err, result, ctx)
    if err then
      print("ERROR: " .. tostring(err))
      return
    end

    if not result or vim.tbl_isempty(result) then
      print("No symbols returned by LSP")
      return
    end

    print("=== LSP Symbols ===")
    print("Total symbols: " .. #result)
    print("")

    -- Helper to print symbol tree
    local function print_symbol(symbol, indent)
      indent = indent or 0
      local prefix = string.rep("  ", indent)

      print(prefix .. "Symbol: " .. symbol.name)
      print(prefix .. "  Kind: " .. symbol.kind)
      if symbol.detail then
        print(prefix .. "  Detail: " .. symbol.detail)
      end
      if symbol.range then
        local range = symbol.range
        print(prefix .. "  Range: L" .. (range.start.line + 1) .. ":" .. (range.start.character + 1))
      end

      -- Check if this looks like a module instantiation
      local kind = symbol.kind
      if kind == 8 or kind == 13 then
        print(prefix .. "  >>> Possible instantiation!")
      end

      if symbol.children then
        print(prefix .. "  Children: " .. #symbol.children)
        for _, child in ipairs(symbol.children) do
          print_symbol(child, indent + 1)
        end
      end
      print("")
    end

    for _, symbol in ipairs(result) do
      print_symbol(symbol)
    end

    print("=== End of Symbols ===")
  end, bufnr)
end

-- Run the inspector
inspect_lsp_symbols()
