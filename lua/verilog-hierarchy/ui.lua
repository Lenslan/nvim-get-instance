local config = require("verilog-hierarchy.config")

local M = {}

M.bufnr = nil
M.winnr = nil
M.source_bufnr = nil

-- Check if hierarchy window is open
function M.is_open()
  return M.winnr ~= nil and vim.api.nvim_win_is_valid(M.winnr)
end

-- Create and display the hierarchy window
function M.open(instantiations, module_name, source_bufnr)
  if M.is_open() then
    return
  end

  M.source_bufnr = source_bufnr

  -- Create a new buffer
  M.bufnr = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_buf_set_option(M.bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(M.bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(M.bufnr, "swapfile", false)
  vim.api.nvim_buf_set_option(M.bufnr, "filetype", "verilog-hierarchy")
  vim.api.nvim_buf_set_option(M.bufnr, "modifiable", false)

  -- Calculate window size
  local width = config.options.window.width
  local height = vim.o.lines - 4

  -- Create window based on position
  local position = config.options.window.position
  local win_config

  if position == "left" then
    vim.cmd("topleft vsplit")
  else
    vim.cmd("botright vsplit")
  end

  M.winnr = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(M.winnr, M.bufnr)
  vim.api.nvim_win_set_width(M.winnr, width)

  -- Set window options
  vim.api.nvim_win_set_option(M.winnr, "number", config.options.display.show_line_numbers)
  vim.api.nvim_win_set_option(M.winnr, "relativenumber", false)
  vim.api.nvim_win_set_option(M.winnr, "cursorline", true)
  vim.api.nvim_win_set_option(M.winnr, "wrap", false)
  vim.api.nvim_win_set_option(M.winnr, "spell", false)

  -- Render content
  M.render(instantiations, module_name)

  -- Set up keybindings
  M.setup_keybindings()
end

-- Close the hierarchy window
function M.close()
  if M.winnr and vim.api.nvim_win_is_valid(M.winnr) then
    vim.api.nvim_win_close(M.winnr, true)
  end
  M.winnr = nil
  M.bufnr = nil
  M.source_bufnr = nil
end

-- Render content in the buffer
function M.render(instantiations, module_name)
  if not M.bufnr or not vim.api.nvim_buf_is_valid(M.bufnr) then
    return
  end

  local lines = {}
  local highlights = {}

  -- Title
  local title = string.format("Module: %s", module_name or "Unknown")
  table.insert(lines, title)
  table.insert(lines, string.rep("─", #title))
  table.insert(lines, "")

  table.insert(highlights, { line = 0, col = 0, text = title, hl_group = "Title" })

  if not instantiations or #instantiations == 0 then
    table.insert(lines, "No instantiations found")
    table.insert(highlights, { line = 3, col = 0, text = "No instantiations found", hl_group = "Comment" })
  else
    local icons = config.options.display.icons
    local indent = config.options.display.indent

    for i, inst in ipairs(instantiations) do
      local line_text = string.format(
        "%s%s %s (line %d)",
        indent,
        icons.instance,
        inst.instance_name,
        inst.line
      )
      table.insert(lines, line_text)

      local detail_text = string.format("%s%sType: %s", indent, indent, inst.module_type)
      table.insert(lines, detail_text)
      table.insert(lines, "")

      -- Store line mapping for jump functionality
      if not M.line_map then
        M.line_map = {}
      end
      M.line_map[#lines - 2] = inst.line

      -- Add highlights
      table.insert(highlights, {
        line = #lines - 3,
        col = #indent,
        end_col = #indent + #icons.instance + #inst.instance_name,
        hl_group = "Function",
      })

      table.insert(highlights, {
        line = #lines - 2,
        col = #indent + #indent + 6,
        end_col = #indent + #indent + 6 + #inst.module_type,
        hl_group = "Type",
      })
    end
  end

  -- Set buffer content
  vim.api.nvim_buf_set_option(M.bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(M.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.bufnr, "modifiable", false)

  -- Apply highlights
  local ns_id = vim.api.nvim_create_namespace("verilog-hierarchy")
  vim.api.nvim_buf_clear_namespace(M.bufnr, ns_id, 0, -1)

  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      M.bufnr,
      ns_id,
      hl.hl_group,
      hl.line,
      hl.col,
      hl.end_col or -1
    )
  end
end

-- Set up keybindings for the hierarchy window
function M.setup_keybindings()
  if not M.bufnr or not vim.api.nvim_buf_is_valid(M.bufnr) then
    return
  end

  local opts = { noremap = true, silent = true, buffer = M.bufnr }

  -- Jump to instantiation
  vim.keymap.set("n", config.options.keybindings.jump, function()
    M.jump_to_instantiation()
  end, opts)

  -- Close window
  vim.keymap.set("n", config.options.keybindings.close, function()
    M.close()
  end, opts)

  -- Also close with <Esc>
  vim.keymap.set("n", "<Esc>", function()
    M.close()
  end, opts)
end

-- Jump to the instantiation in the source file
function M.jump_to_instantiation()
  if not M.line_map or not M.source_bufnr then
    return
  end

  local current_line = vim.api.nvim_win_get_cursor(M.winnr)[1]
  local target_line = M.line_map[current_line]

  if target_line then
    -- Find window with source buffer
    local source_win = nil
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == M.source_bufnr and win ~= M.winnr then
        source_win = win
        break
      end
    end

    if source_win then
      vim.api.nvim_set_current_win(source_win)
      vim.api.nvim_win_set_cursor(source_win, { target_line, 0 })
      vim.cmd("normal! zz")
    else
      -- If no window found, close hierarchy and open in current window
      M.close()
      vim.api.nvim_set_current_buf(M.source_bufnr)
      vim.api.nvim_win_set_cursor(0, { target_line, 0 })
      vim.cmd("normal! zz")
    end
  end
end

return M
