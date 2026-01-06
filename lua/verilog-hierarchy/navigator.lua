local parser = require("verilog-hierarchy.parser")
local ui = require("verilog-hierarchy.ui")

local M = {}

-- Toggle the hierarchy window
function M.toggle()
  if ui.is_open() then
    ui.close()
  else
    M.open()
  end
end

-- Open the hierarchy window for current buffer
function M.open()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

  -- Check if current buffer is a Verilog file
  if filetype ~= "verilog" and filetype ~= "systemverilog" then
    vim.notify("Current buffer is not a Verilog file", vim.log.levels.WARN)
    return
  end

  -- Get module name
  local module_name = parser.get_current_module(bufnr)

  -- Get instantiations (with async callback support)
  parser.get_instantiations(bufnr, function(instantiations)
    if not instantiations or vim.tbl_isempty(instantiations) then
      vim.notify("No module instantiations found", vim.log.levels.INFO)
      -- Still open UI to show empty state
      ui.open({}, module_name, bufnr)
      return
    end

    -- Open UI with results
    ui.open(instantiations, module_name, bufnr)
  end)
end

-- Close the hierarchy window
function M.close()
  ui.close()
end

-- Refresh the hierarchy window
function M.refresh()
  if not ui.is_open() then
    return
  end

  local source_bufnr = ui.source_bufnr
  if not source_bufnr or not vim.api.nvim_buf_is_valid(source_bufnr) then
    ui.close()
    return
  end

  -- Get updated data
  local module_name = parser.get_current_module(source_bufnr)

  -- Get instantiations with async callback
  parser.get_instantiations(source_bufnr, function(instantiations)
    if instantiations and ui.is_open() then
      ui.render(instantiations, module_name)
    end
  end)
end

return M
