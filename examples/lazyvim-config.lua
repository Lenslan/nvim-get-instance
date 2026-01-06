-- LazyVim 配置示例
-- 将此文件放在 ~/.config/nvim/lua/plugins/verilog-hierarchy.lua

return {
  {
    -- 本地开发路径，替换为你的实际路径
    dir = "D:/other-proj/nvim-get-instance",
    -- 或者使用 GitHub 路径（发布后）:
    -- "your-username/verilog-hierarchy.nvim",

    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },

    -- 只在打开 Verilog 文件时加载
    ft = { "verilog", "systemverilog" },

    config = function()
      require("verilog-hierarchy").setup({
        window = {
          width = 40,
          position = "left", -- "left" 或 "right"
        },
        keybindings = {
          toggle = "<leader>vh",  -- 切换层级窗口
          jump = "<CR>",          -- 跳转到实例化行
          close = "q",            -- 关闭层级窗口
        },
        display = {
          show_line_numbers = true,
          indent = "  ",
          icons = {
            module = "▸ ",
            instance = "→ ",
          },
        },
      })
    end,

    -- 可选：添加快捷键描述（用于 which-key）
    keys = {
      { "<leader>vh", desc = "Toggle Verilog Hierarchy" },
    },
  },

  -- 确保安装 treesitter 的 Verilog parser
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "verilog" })
      end
    end,
  },
}
