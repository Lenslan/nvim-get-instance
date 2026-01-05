# Verilog 层级导航器

一个 Neovim 插件，用于帮助芯片设计工程师快速查看和导航 Verilog 模块的例化层级关系。

## 功能特性

- 🔍 **智能解析**: 使用 Tree-sitter 准确识别模块例化
- 🪟 **浮动窗口**: 在美观的浮动窗口中显示例化列表
- ⚡ **快速跳转**: 一键跳转到例化位置或模块定义
- 🔄 **自动回退**: Tree-sitter 不可用时自动使用正则表达式解析
- 🎨 **可配置**: 支持自定义快捷键、窗口样式等

## 安装

### 使用 [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'your-username/verilog-hierarchy-navigator',
  ft = { 'verilog', 'systemverilog' },
  config = function()
    require('verilog-hierarchy').setup()
  end,
}
```

### 使用 [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'your-username/verilog-hierarchy-navigator',
  ft = { 'verilog', 'systemverilog' },
  config = function()
    require('verilog-hierarchy').setup()
  end,
}
```

## 依赖

### 必需
- Neovim >= 0.8.0

### 可选（推荐）
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) - 用于更准确的语法解析
- Verilog LSP 服务器（如 [verible-verilog-ls](https://github.com/chipsalliance/verible) 或 [svls](https://github.com/dalance/svls)）- 用于跳转到定义

## 配置

### 默认配置

```lua
require('verilog-hierarchy').setup({
  -- 快捷键配置
  keymaps = {
    show_hierarchy = '<leader>vh',  -- 显示层级
    jump_to_def = '<leader>vd',     -- 跳转到定义
  },
  
  -- UI 配置
  ui = {
    window_type = 'float',  -- 'float' 或 'split'
    width_ratio = 0.6,      -- 浮动窗口宽度比例
    height_ratio = 0.5,     -- 浮动窗口高度比例
    border = 'rounded',     -- 边框样式: 'none', 'single', 'double', 'rounded'
  },
  
  -- 解析器配置
  parser = {
    use_treesitter = true,  -- 优先使用 Tree-sitter
    fallback_regex = true,  -- 启用正则表达式回退
  },
})
```

### 自定义配置示例

```lua
require('verilog-hierarchy').setup({
  keymaps = {
    show_hierarchy = '<leader>vi',  -- 自定义快捷键
    jump_to_def = 'gd',
  },
  ui = {
    border = 'double',
    width_ratio = 0.8,
  },
})
```

## 使用方法

### 显示模块例化层级

1. 在 Verilog 文件中，按下 `<leader>vh`（或你配置的快捷键）
2. 插件会显示一个浮动窗口，列出当前模块的所有例化
3. 使用 `j`/`k` 或方向键上下移动
4. 按 `Enter` 跳转到选中的例化位置
5. 按 `q` 或 `Esc` 关闭窗口

### 跳转到模块定义

1. 将光标移动到模块名称上
2. 按下 `<leader>vd`（或你配置的快捷键）
3. 如果 LSP 可用，会直接跳转到模块定义
4. 否则会在项目中搜索模块定义并打开 quickfix 列表

### 命令

插件提供以下命令：

- `:VerilogHierarchy` - 显示模块层级
- `:VerilogJumpDef` - 跳转到模块定义

## 示例

假设有以下 Verilog 代码：

```verilog
module top (
  input clk,
  input rst,
  output [7:0] data_out
);

  wire [7:0] adder_out;
  wire [7:0] mult_out;
  
  adder #(.WIDTH(8)) u_adder (
    .a(data_in),
    .b(8'h01),
    .sum(adder_out)
  );
  
  multiplier u_mult (
    .clk(clk),
    .a(adder_out),
    .b(8'h02),
    .product(mult_out)
  );
  
  register_file #(.DEPTH(16)) u_regfile (
    .clk(clk),
    .rst(rst),
    .data_in(mult_out),
    .data_out(data_out)
  );

endmodule
```

按下 `<leader>vh` 后，会显示：

```
┌─────────────────────────────────────┐
│      Module Instantiations          │
├─────────────────────────────────────┤
│ [9] adder u_adder                   │
│ [15] multiplier u_mult              │
│ [21] register_file u_regfile        │
└─────────────────────────────────────┘
```

## Tree-sitter 设置

如果你使用 nvim-treesitter，确保安装了 Verilog parser：

```lua
require('nvim-treesitter.configs').setup({
  ensure_installed = { 'verilog', 'systemverilog' },
})
```

或手动安装：

```vim
:TSInstall verilog
```

## 故障排除

### Tree-sitter 不工作

如果看到警告 "Tree-sitter not available, using fallback parser"：

1. 确保安装了 nvim-treesitter
2. 运行 `:TSInstall verilog` 安装 Verilog parser
3. 检查 `:checkhealth nvim-treesitter`

### LSP 不工作

如果跳转到定义功能不工作：

1. 确保安装了 Verilog LSP 服务器
2. 检查 LSP 是否正在运行：`:LspInfo`
3. 插件会自动回退到基于搜索的方法

### 找不到例化

如果插件没有找到例化：

1. 确保文件类型正确：`:set filetype?` 应该显示 `verilog` 或 `systemverilog`
2. 检查代码语法是否正确
3. 尝试手动设置文件类型：`:set filetype=verilog`

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 致谢

- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) - Tree-sitter 集成
- [Neovim](https://neovim.io/) - 强大的编辑器
