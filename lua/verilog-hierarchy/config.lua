local M = {}

M.defaults = {
  -- Window configuration
  window = {
    width = 40,
    position = "left", -- "left" or "right"
  },

  -- Keybindings
  keybindings = {
    toggle = "<leader>vh", -- Toggle hierarchy window
    jump = "<CR>",         -- Jump to instantiation line
    close = "q",           -- Close hierarchy window
  },

  -- Display options
  display = {
    show_line_numbers = true,
    indent = "  ",
    icons = {
      module = "▸ ",
      instance = "→ ",
    },
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
