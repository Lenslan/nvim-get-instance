local M = {}

-- Helper function to get treesitter parser (tries systemverilog first, then verilog)
local function get_verilog_parser(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Try systemverilog first (tree-sitter-verilog uses this name)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "systemverilog")
  if ok then
    return parser
  end

  -- Fallback to verilog
  ok, parser = pcall(vim.treesitter.get_parser, bufnr, "systemverilog")
  if ok then
    return parser
  end

  return nil
end

-- Get LSP client for Verilog/SystemVerilog
local function get_verilog_lsp_client(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Get all active clients for this buffer
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  -- Find a client that supports documentSymbol
  for _, client in ipairs(clients) do
    if client.server_capabilities.documentSymbolProvider then
      return client
    end
  end

  return nil
end

-- Get module type at a specific line using treesitter
local function get_module_type_at_line(bufnr, line)
  local parser = get_verilog_parser(bufnr)
  if not parser then
    return nil
  end

  local tree = parser:parse()[1]
  local root = tree:root()
  local target_line = line - 1

  -- Get the smallest node at the target line
  local node = root:descendant_for_range(target_line, 0, target_line, 999)

  if not node then
    return nil
  end

  -- Find the module_instantiation ancestor
  local current = node
  while current do
    if current:type() == "module_instantiation" then
      -- Found it! Now get the module type (first child should be the module identifier)
      local first_child = current:child(0)
      if first_child then
        local ok, text = pcall(vim.treesitter.get_node_text, first_child, bufnr)
        if ok then
          return text
        end
      end
      return nil
    end
    current = current:parent()
  end

  return nil
end

-- Verify if a position is a module instantiation using treesitter
local function verify_instantiation_at_line(bufnr, line)
  local parser = get_verilog_parser(bufnr)
  if not parser then
    return false
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  -- Convert 1-indexed line to 0-indexed for treesitter
  local target_line = line - 1

  -- Get the smallest node at the target line
  local node = root:descendant_for_range(target_line, 0, target_line, 999)

  if not node then
    return false
  end

  -- Check if this node or any ancestor is module_instantiation
  local current = node
  while current do
    if current:type() == "module_instantiation" then
      return true
    end
    current = current:parent()
  end

  return false
end

-- Parse document symbols to extract module instantiations
local function parse_symbols(symbols, instantiations, bufnr)
  instantiations = instantiations or {}

  if not symbols then
    return instantiations
  end

  for _, symbol in ipairs(symbols) do
    -- Check if this is a module instantiation
    -- In Verilog LSP, module instances typically have kind 13 (Variable) or kind 8 (Instance)
    -- We need to check the symbol name pattern to identify instantiations
    local kind = symbol.kind
    local name = symbol.name

    -- LSP SymbolKind values:
    -- 1=File, 2=Module, 3=Namespace, 4=Package, 5=Class, 6=Method, 7=Property,
    -- 8=Field, 9=Constructor, 10=Enum, 11=Interface, 12=Function, 13=Variable,
    -- 14=Constant, 15=String, 16=Number, 17=Boolean, 18=Array, 19=Object,
    -- 20=Key, 21=Null, 22=EnumMember, 23=Struct, 24=Event, 25=Operator, 26=TypeParameter

    local is_instantiation = false
    local module_type = nil
    local instance_name = name

    -- Strategy: If LSP provides detail, use it for filtering
    -- If no detail, use treesitter to verify it's really an instantiation
    if symbol.detail then
      local detail = symbol.detail:lower()

      -- Filter out reg/wire/logic signal definitions
      if detail:match("^reg%s") or detail:match("^wire%s") or
         detail:match("^logic%s") or detail:match("^integer%s") or
         detail:match("^bit%s") or detail:match("^byte%s") or
         detail:match("^shortint%s") or detail:match("^int%s") or
         detail:match("^longint%s") or detail:match("^time%s") or
         detail:match("^realtime%s") or detail:match("^real%s") or
         detail:match("^shortreal%s") then
        -- This is a signal declaration, skip it
        goto continue
      end

      -- Also skip if it looks like an array or bus declaration
      if detail:match("^%[") then
        goto continue
      end

      -- Try to extract module type from detail
      local detail_orig = symbol.detail
      module_type = detail_orig:match("^([%w_]+)%s+[%w_]+")
      if not module_type then
        module_type = detail_orig:match("[Tt]ype:%s*([%w_]+)")
      end
      if not module_type then
        module_type = detail_orig:match("^([%w_]+)")
      end

      if module_type then
        is_instantiation = true
      end
    else
      -- No detail field - verible case
      -- Use treesitter to verify if this is really a module instantiation
      if (kind == 8 or kind == 13) and symbol.range then
        local line = symbol.range.start.line + 1
        local verified = verify_instantiation_at_line(bufnr, line)
        print(string.format("[DEBUG] Symbol '%s' at L%d: verified=%s", name, line, tostring(verified)))
        if verified then
          is_instantiation = true
          -- Try to get module type from treesitter
          module_type = get_module_type_at_line(bufnr, line) or "unknown"
          print(string.format("[DEBUG] Module type: '%s'", tostring(module_type)))
        end
      end
    end

    if is_instantiation then
      print(string.format("[DEBUG] Adding instantiation: %s (%s) at L%d", instance_name, tostring(module_type), symbol.range.start.line + 1))
      -- Get the range
      local range = symbol.range or symbol.location and symbol.location.range
      if range then
        table.insert(instantiations, {
          module_type = module_type,
          instance_name = instance_name,
          line = range.start.line + 1, -- LSP uses 0-indexed, convert to 1-indexed
          col = range.start.character + 1,
          end_line = range["end"].line + 1,
          end_col = range["end"].character + 1,
        })
        print(string.format("[DEBUG] Added! Total count: %d", #instantiations))
      else
        print("[DEBUG] No range found, skipped")
      end
    end

    ::continue::

    -- Recursively process children
    if symbol.children then
      print(string.format("[DEBUG] Symbol '%s' has %d children, processing recursively", name, #symbol.children))
      parse_symbols(symbol.children, instantiations, bufnr)
    end
  end

  print(string.format("[DEBUG] parse_symbols returning %d instantiations", #instantiations))
  return instantiations
end

-- Parse using treesitter as fallback
local function parse_with_treesitter(bufnr)
  local parser = get_verilog_parser(bufnr)
  if not parser then
    return nil
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  local instantiations = {}

  -- Traverse the tree to find module_instantiation nodes
  local function traverse(node)
    if node:type() == "module_instantiation" then
      local module_type = nil
      local instance_name = nil
      local start_row, start_col, end_row, end_col = node:range()

      -- Get first child (module type)
      local child = node:child(0)
      if child and child:type() == "simple_identifier" then
        module_type = vim.treesitter.get_node_text(child, bufnr)
      end

      -- Find instance name in children
      for i = 0, node:child_count() - 1 do
        local c = node:child(i)
        if c:type() == "name_of_instance" then
          -- Get the identifier inside name_of_instance
          for j = 0, c:child_count() - 1 do
            local name_child = c:child(j)
            if name_child:type() == "simple_identifier" then
              instance_name = vim.treesitter.get_node_text(name_child, bufnr)
              break
            end
          end
          break
        end
      end

      if module_type and instance_name then
        table.insert(instantiations, {
          module_type = module_type,
          instance_name = instance_name,
          line = start_row + 1,
          col = start_col + 1,
          end_line = end_row + 1,
          end_col = end_col + 1,
        })
      end
    end

    -- Traverse children
    for i = 0, node:child_count() - 1 do
      traverse(node:child(i))
    end
  end

  traverse(root)

  -- Sort by line number
  table.sort(instantiations, function(a, b)
    return a.line < b.line
  end)

  return instantiations
end

-- Get module instantiations using LSP or treesitter fallback
function M.get_instantiations(bufnr, callback)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Try LSP first
  local client = get_verilog_lsp_client(bufnr)

  if client then
    -- Request document symbols from LSP
    local params = {
      textDocument = vim.lsp.util.make_text_document_params(bufnr)
    }

    client.request("textDocument/documentSymbol", params, function(err, result, ctx)
      if err then
        vim.notify("LSP request failed: " .. tostring(err), vim.log.levels.WARN)
        -- Fallback to treesitter
        local ts_result = parse_with_treesitter(bufnr)
        if callback then
          callback(ts_result)
        end
        return
      end

      if not result or vim.tbl_isempty(result) then
        -- No symbols found, try treesitter
        local ts_result = parse_with_treesitter(bufnr)
        if callback then
          callback(ts_result)
        end
        return
      end

      -- Parse the symbols with bufnr for treesitter validation
      print(string.format("[DEBUG] LSP returned %d symbols, parsing...", #result))
      local instantiations = parse_symbols(result, nil, bufnr)

      -- Sort by line number
      table.sort(instantiations, function(a, b)
        return a.line < b.line
      end)

      print(string.format("[DEBUG] Final result: %d instantiations, calling callback", #instantiations))
      if callback then
        callback(instantiations)
      end
    end, bufnr)

    -- Return nil to indicate async operation
    return nil
  else
    -- No LSP client, use treesitter directly
    local result = parse_with_treesitter(bufnr)

    if not result then
      vim.notify("No LSP client found and treesitter parsing failed", vim.log.levels.ERROR)
      return {}
    end

    if callback then
      callback(result)
    end
    return result
  end
end

-- Get the current module name using LSP or treesitter
function M.get_current_module(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Try treesitter first for module name (simpler and faster)
  local parser = get_verilog_parser(bufnr)
  if parser then
    local tree = parser:parse()[1]
    local root = tree:root()

    -- Find module declaration
    local function find_module(node)
      if node:type() == "module_declaration" then
        -- Get module name (usually second child after "module" keyword)
        for i = 0, node:child_count() - 1 do
          local child = node:child(i)
          if child:type() == "simple_identifier" then
            return vim.treesitter.get_node_text(child, bufnr)
          end
        end
      end

      -- Search children
      for i = 0, node:child_count() - 1 do
        local result = find_module(node:child(i))
        if result then
          return result
        end
      end

      return nil
    end

    local module_name = find_module(root)
    if module_name then
      return module_name
    end
  end

  -- Fallback: try to extract from buffer name or first line
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename then
    local name = filename:match("([^/\\]+)%.s?v$")
    if name then
      return name
    end
  end

  return "Unknown"
end

return M
