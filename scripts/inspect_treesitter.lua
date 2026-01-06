-- Script to inspect treesitter tree structure
-- Run: :luafile scripts/inspect_treesitter.lua

local function inspect_tree()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

  print("=== Treesitter Tree Inspector ===")
  print("Buffer: " .. bufnr)
  print("Filetype: " .. filetype)
  print("")

  if filetype ~= "verilog" and filetype ~= "systemverilog" then
    print("ERROR: Not a Verilog file!")
    return
  end

  local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, "verilog")
  if not parser_ok then
    print("ERROR: No treesitter parser available")
    return
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  print("Root node type: " .. root:type())
  print("")

  -- Print tree structure
  local function print_node(node, indent, max_depth)
    if max_depth and indent > max_depth then
      return
    end

    indent = indent or 0
    local prefix = string.rep("  ", indent)

    local start_row, start_col, end_row, end_col = node:range()
    local node_type = node:type()

    -- Get node text for small nodes
    local text = ""
    if end_row - start_row < 3 and node:child_count() == 0 then
      local ok, node_text = pcall(vim.treesitter.get_node_text, node, bufnr)
      if ok then
        text = ' "' .. node_text:gsub("\n", "\\n") .. '"'
      end
    end

    print(string.format("%s%s [%d:%d - %d:%d]%s",
      prefix, node_type, start_row + 1, start_col, end_row + 1, end_col, text))

    -- Highlight module instantiation related nodes
    if node_type == "module_instantiation" or
       node_type == "hierarchical_instance" or
       node_type == "name_of_instance" or
       node_type == "instance_identifier" then
      print(prefix .. "  ^^^ IMPORTANT: This is instantiation-related!")
    end

    for i = 0, node:child_count() - 1 do
      print_node(node:child(i), indent + 1, max_depth)
    end
  end

  print("=== Tree Structure (max depth: 10) ===")
  print_node(root, 0, 10)
  print("")
  print("=== Looking for module_instantiation nodes ===")

  -- Find all module_instantiation nodes
  local function find_instantiations(node, results)
    results = results or {}

    if node:type() == "module_instantiation" then
      local start_row, start_col = node:range()
      table.insert(results, {
        line = start_row + 1,
        col = start_col + 1,
        node = node
      })
    end

    for i = 0, node:child_count() - 1 do
      find_instantiations(node:child(i), results)
    end

    return results
  end

  local instantiations = find_instantiations(root)
  print("Found " .. #instantiations .. " module_instantiation nodes:")
  print("")

  for _, inst in ipairs(instantiations) do
    print("Line " .. inst.line .. ":")
    print_node(inst.node, 1, 3)
    print("")
  end
end

inspect_tree()
