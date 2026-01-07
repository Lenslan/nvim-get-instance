# verilog-hierarchy.nvim

一个用于 Neovim 的 Verilog 模块层级导航插件，帮助芯片设计工程师快速查看和导航 Verilog 代码中的模块实例化关系。

## 功能特性

- 🔍 使用 LSP 精确解析 Verilog 文件中的模块实例化（支持 treesitter 备用）
- 🌳 以侧边栏树形结构展示模块层级
- ⚡ 快速跳转到实例化代码位置
- 🎨 语法高亮和美观的显示界面
- ⌨️ 可自定义的快捷键
- 🔄 自动刷新（保存文件时）
- 🩺 内置健康检查

## 依赖要求

### 必需
- Neovim >= 0.8.0
- Verilog/SystemVerilog LSP 服务器（推荐以下之一）：
  - [svls](https://github.com/dalance/svls) - SystemVerilog Language Server
  - [verible-verilog-ls](https://github.com/chipsalliance/verible) - Verible Verilog Language Server
  - [hdl_checker](https://github.com/suoto/hdl_checker) - HDL Checker

### 可选（用于备用解析）
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- Verilog treesitter parser (通过 `:TSInstall verilog` 安装)

## 安装

### 使用 [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "Lenslan/nvim-get-instance",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  ft = { "verilog", "systemverilog" },
  config = function()
    require("verilog-hierarchy").setup({
      -- 可选配置，使用默认配置可省略
      window = {
        width = 40,
        position = "left", -- "left" 或 "right"
      },
      keybindings = {
        toggle = "<leader>h",  -- 切换层级窗口
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
}
```

### 使用 [packer.nvim](https://github.com/wejrowski/packer.nvim)

```lua
use {
  "your-username/verilog-hierarchy.nvim",
  requires = { "nvim-treesitter/nvim-treesitter" },
  ft = { "verilog", "systemverilog" },
  config = function()
    require("verilog-hierarchy").setup()
  end
}
```

## 使用方法

### 快捷键

默认快捷键：

- `<leader>vh` - 切换层级窗口的显示/隐藏
- `<CR>` (在层级窗口中) - 跳转到选中的实例化位置
- `q` 或 `<Esc>` (在层级窗口中) - 关闭层级窗口

### 命令

插件提供以下用户命令：

- `:VerilogHierarchyToggle` - 切换层级窗口
- `:VerilogHierarchyOpen` - 打开层级窗口
- `:VerilogHierarchyClose` - 关闭层级窗口
- `:VerilogHierarchyRefresh` - 刷新层级窗口内容

### Lua API

```lua
local verilog_hierarchy = require("verilog-hierarchy")

-- 切换层级窗口
verilog_hierarchy.toggle()

-- 打开层级窗口
verilog_hierarchy.open()

-- 关闭层级窗口
verilog_hierarchy.close()

-- 刷新层级窗口
verilog_hierarchy.refresh()
```

## 配置

### 默认配置

```lua
{
  window = {
    width = 40,              -- 窗口宽度
    position = "left",       -- 窗口位置: "left" 或 "right"
  },
  keybindings = {
    toggle = "<leader>vh",   -- 切换窗口的全局快捷键
    jump = "<CR>",           -- 跳转到实例化（在层级窗口中）
    close = "q",             -- 关闭窗口（在层级窗口中）
  },
  display = {
    show_line_numbers = true, -- 显示行号
    indent = "  ",           -- 缩进字符
    icons = {
      module = "▸ ",         -- 模块图标
      instance = "→ ",       -- 实例图标
    },
  },
}
```

### 自定义配置示例

```lua
require("verilog-hierarchy").setup({
  window = {
    width = 50,
    position = "right",
  },
  keybindings = {
    toggle = "<leader>vt",
  },
  display = {
    icons = {
      module = "📦 ",
      instance = "🔗 ",
    },
  },
})
```
