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
  "your-username/verilog-hierarchy.nvim",
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

## 使用示例

1. 打开一个 Verilog 文件
2. 按下 `<leader>vh` 打开层级窗口
3. 窗口会显示当前模块的所有实例化：
   ```
   Module: top_module
   ──────────────────

     → proc_inst (line 15)
       Type: data_processor

     → fifo_inst (line 24)
       Type: fifo

     → reg_stage1 (line 35)
       Type: register
   ```
4. 移动光标到某个实例上，按 `<CR>` 跳转到源代码位置
5. 按 `q` 关闭层级窗口

## 健康检查

运行以下命令检查插件状态：

```vim
:checkhealth verilog-hierarchy
```

这将检查：
- Neovim 版本
- LSP 服务器连接状态
- LSP documentSymbol 支持
- Treesitter 安装状态（用于备用）
- 插件加载状态

## 故障排除

### LSP 服务器未连接

如果看到 "No LSP client found"，请确保：

1. 已安装 Verilog LSP 服务器（svls、verible-verilog-ls 或 hdl_checker）
2. LSP 服务器已在 Neovim 配置中正确设置

**安装 svls 示例：**
```bash
# 使用 cargo 安装
cargo install svls

# 在 Neovim 配置中添加（LazyVim + nvim-lspconfig）
-- ~/.config/nvim/lua/plugins/lsp.lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        svls = {},
      },
    },
  },
}
```

### 没有找到模块实例化

如果插件显示 "No module instantiations found"，可能的原因：

1. **LSP 未返回符号**：运行调试脚本查看 LSP 返回的符号
   ```vim
   :luafile scripts/debug_lsp_symbols.lua
   ```
   这将显示 LSP 返回的所有符号，帮助你了解 LSP 如何标记实例化

2. **符号类型不匹配**：不同的 LSP 服务器可能使用不同的符号类型。如果遇到这个问题，请在 GitHub 上提 issue，附上调试脚本的输出

3. **Verilog 语法错误**：确保你的 Verilog 代码语法正确，LSP 才能正确解析

### 使用 Treesitter 备用模式

如果 LSP 不可用，插件会自动使用 treesitter 解析。确保安装：

```vim
:TSInstall verilog
```

### 测试插件功能

运行测试脚本：
```vim
:e examples/sample.v
:luafile scripts/test_plugin.lua
```

这将测试所有核心功能并给出详细报告。

## 开发

### 项目结构

```
.
├── lua/
│   └── verilog-hierarchy/
│       ├── init.lua        # 插件主入口
│       ├── config.lua      # 配置管理
│       ├── parser.lua      # LSP/Treesitter 解析器
│       ├── ui.lua          # UI 渲染
│       ├── navigator.lua   # 导航逻辑
│       └── health.lua      # 健康检查
├── plugin/
│   └── verilog-hierarchy.lua  # 插件加载入口
├── scripts/
│   ├── debug_lsp_symbols.lua  # LSP 调试脚本
│   └── test_plugin.lua        # 插件测试脚本
├── queries/
│   └── verilog/
│       └── instantiations.scm # Treesitter 查询（备用）
└── examples/
    ├── sample.v               # 示例 Verilog 文件
    └── lazyvim-config.lua     # LazyVim 配置示例
```

### 测试

在项目根目录下打开示例文件进行测试：

```vim
:e examples/sample.v
:lua require("verilog-hierarchy").setup()
:VerilogHierarchyToggle
```

或运行完整测试：

```vim
:e examples/sample.v
:luafile scripts/test_plugin.lua
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 致谢

- [nvim-navic](https://github.com/SmiteshP/nvim-navic) - LSP 符号导航的灵感来源
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) - 强大的语法解析工具
- 所有贡献者和用户

## 更新日志

### v1.1.0 (当前版本)

- ✨ 改用 LSP `textDocument/documentSymbol` 进行主要解析，更加准确
- ✨ Treesitter 作为备用方案，无 LSP 时自动启用
- ✨ 新增调试脚本 `debug_lsp_symbols.lua` 帮助诊断 LSP 问题
- ✨ 新增测试脚本 `test_plugin.lua` 用于功能验证
- 🔧 改进健康检查，支持 LSP 状态检测
- 📝 更新文档，包含 LSP 配置说明

### v1.0.0

- 初始版本发布
- 基于 treesitter 的模块实例化解析
- 侧边栏树形显示
- 跳转导航功能
- 可自定义配置
- 健康检查支持
