-- Test script for verilog-hierarchy plugin
-- Usage: Open examples/sample.v and run :luafile scripts/test_plugin.lua

print("=== Testing verilog-hierarchy plugin ===")

-- Test 1: Check if plugin can be loaded
print("\n[Test 1] Loading plugin...")
local ok, verilog_hierarchy = pcall(require, "verilog-hierarchy")
if ok then
  print("✓ Plugin loaded successfully")
else
  print("✗ Failed to load plugin: " .. tostring(verilog_hierarchy))
  return
end

-- Test 2: Check parser module
print("\n[Test 2] Loading parser module...")
local parser_ok, parser = pcall(require, "verilog-hierarchy.parser")
if parser_ok then
  print("✓ Parser module loaded")
else
  print("✗ Failed to load parser: " .. tostring(parser))
  return
end

-- Test 3: Test get_current_module
print("\n[Test 3] Getting current module name...")
local bufnr = vim.api.nvim_get_current_buf()
local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
print("  Buffer filetype: " .. filetype)

if filetype ~= "verilog" and filetype ~= "systemverilog" then
  print("✗ Not a Verilog file. Please open examples/sample.v first")
  return
end

local module_name = parser.get_current_module(bufnr)
print("  Module name: " .. tostring(module_name))
if module_name and module_name ~= "Unknown" then
  print("✓ Module name detected")
else
  print("⚠ Module name could not be detected")
end

-- Test 4: Test get_instantiations
print("\n[Test 4] Getting module instantiations...")
print("  This may take a moment if using LSP...")

parser.get_instantiations(bufnr, function(instantiations)
  if not instantiations then
    print("✗ Failed to get instantiations")
    return
  end

  print("  Found " .. #instantiations .. " instantiation(s)")

  if #instantiations > 0 then
    print("✓ Instantiations detected:")
    for i, inst in ipairs(instantiations) do
      print(string.format("    %d. %s (type: %s) at line %d",
        i, inst.instance_name, inst.module_type, inst.line))
    end
  else
    print("⚠ No instantiations found")
  end

  -- Test 5: Test UI module
  print("\n[Test 5] Testing UI module...")
  local ui_ok, ui = pcall(require, "verilog-hierarchy.ui")
  if ui_ok then
    print("✓ UI module loaded")

    -- Try to open the UI
    print("\n[Test 6] Opening hierarchy window...")
    verilog_hierarchy.open()
    print("  Check if a window appeared on the left/right")
    print("  You should see the hierarchy window with instantiations")

    vim.defer_fn(function()
      if ui.is_open() then
        print("✓ Hierarchy window is open")
        print("\nTest window features:")
        print("  - Press <CR> to jump to an instantiation")
        print("  - Press 'q' or <Esc> to close")
        print("  - Press <leader>vh to toggle")
      else
        print("⚠ Hierarchy window did not open")
      end

      print("\n=== Tests completed ===")
      print("If the hierarchy window opened with instantiations, the plugin is working!")
      print("Run :checkhealth verilog-hierarchy for more diagnostics")
    end, 500)
  else
    print("✗ Failed to load UI module: " .. tostring(ui))
  end
end)
