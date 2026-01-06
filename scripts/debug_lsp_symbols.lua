-- Debug script to inspect LSP symbols and treesitter validation
-- Run this in Neovim with :luafile scripts/debug_lsp_symbols.lua

local function verify_instantiation_at_line(bufnr, line)
  local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, "verilog")
  if not parser_ok then
    return false, "No treesitter parser"
  end

  local tree = parser:parse()[1]
  local root = tree:root()
  local target_line = line - 1

  -- Get the smallest node at the target line
  local node = root:descendant_for_range(target_line, 0, target_line, 999)

  if not node then
    return false, "No node at line"
  end

  -- Check if this node or any ancestor is module_instantiation
  local current = node
  local node_types = {}
  while current do
    table.insert(node_types, current:type())
    if current:type() == "module_instantiation" then
      return true, "Found module_instantiation ancestor: " .. table.concat(node_types, " <- ")
    end
    current = current:parent()
  end

  return false, "No module_instantiation ancestor. Path: " .. table.concat(node_types, " <- ")
end

local function inspect_lsp_symbols()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

  print("=== LSP Symbol Inspector with Treesitter Validation ===")
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

    print("=== LSP Symbols with Treesitter Validation ===")
    print("Total symbols: " .. #result)
    print("")

    local filtered_by_detail = 0
    local filtered_by_treesitter = 0
    local instantiation_count = 0

    -- Helper to check if should be filtered by detail
    local function should_filter_by_detail(symbol)
      if not symbol.detail then
        return false
      end

      local detail = symbol.detail:lower()
      if detail:match("^reg%s") or detail:match("^wire%s") or
         detail:match("^logic%s") or detail:match("^integer%s") or
         detail:match("^bit%s") or detail:match("^byte%s") or
         detail:match("^%[") then
        return true
      end
      return false
    end

    -- Helper to print symbol tree
    local function print_symbol(symbol, indent)
      indent = indent or 0
      local prefix = string.rep("  ", indent)

      local has_detail = symbol.detail ~= nil
      local is_filtered_by_detail = should_filter_by_detail(symbol)
      local filter_marker = ""
      local kind = symbol.kind

      print(prefix .. "Symbol: " .. symbol.name)
      print(prefix .. "  Kind: " .. kind)

      if has_detail then
        print(prefix .. "  Detail: " .. symbol.detail)
      else
        print(prefix .. "  Detail: (none)")
      end

      if symbol.range then
        local range = symbol.range
        local line = range.start.line + 1
        print(prefix .. "  Range: L" .. line .. ":" .. (range.start.character + 1))

        -- Check with treesitter if it's kind 8 or 13
        if kind == 8 or kind == 13 then
          if is_filtered_by_detail then
            print(prefix .. "  >>> [FILTERED BY DETAIL] Signal declaration")
            filtered_by_detail = filtered_by_detail + 1
          else
            -- Verify with treesitter
            local is_inst, reason = verify_instantiation_at_line(bufnr, line)
            if has_detail then
              if is_inst then
                print(prefix .. "  >>> [PASS] Has detail + treesitter confirms")
                print(prefix .. "      " .. reason)
                instantiation_count = instantiation_count + 1
              else
                print(prefix .. "  >>> [UNCERTAIN] Has detail but treesitter doesn't confirm")
                print(prefix .. "      " .. reason)
                instantiation_count = instantiation_count + 1  -- Still count it
              end
            else
              -- No detail - rely on treesitter
              if is_inst then
                print(prefix .. "  >>> [PASS] No detail but treesitter confirms")
                print(prefix .. "      " .. reason)
                instantiation_count = instantiation_count + 1
              else
                print(prefix .. "  >>> [FILTERED BY TREESITTER] Not module_instantiation")
                print(prefix .. "      " .. reason)
                filtered_by_treesitter = filtered_by_treesitter + 1
              end
            end
          end
        end
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

    print("=== Summary ===")
    print("Total symbols: " .. #result)
    print("Filtered by detail (signals): " .. filtered_by_detail)
    print("Filtered by treesitter: " .. filtered_by_treesitter)
    print("Module instantiations: " .. instantiation_count)
    print("")
    print("Strategy:")
    print("  - If symbol has detail: use detail to filter reg/wire/logic")
    print("  - If no detail + kind 8/13: use treesitter to verify")
    print("  - Only symbols verified as module_instantiation are shown")
    print("")
    print("=== End of Symbols ===")
  end, bufnr)
end

-- Run the inspector
inspect_lsp_symbols()
