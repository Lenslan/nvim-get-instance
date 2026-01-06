# 快速开始指南

## 1. 前置要求

确保你已经安装：
- Neovim >= 0.8.0
- LazyVim 或其他 Neovim 配置
- nvim-treesitter 插件

## 2. 安装步骤

### 在 LazyVim 中安装

1. 复制 `examples/lazyvim-config.lua` 到你的 LazyVim 插件目录：
   ```bash
   cp examples/lazyvim-config.lua ~/.config/nvim/lua/plugins/verilog-hierarchy.lua
   ```

2. 编辑该文件，修改 `dir` 路径为你的插件实际路径：
   ```lua
   dir = "D:/other-proj/nvim-get-instance",  -- 修改为你的路径
   ```

3. 重启 Neovim，插件会自动安装

4. 安装 Verilog treesitter parser：
   ```vim
   :TSInstall verilog
   ```

## 3. 验证安装

打开 Neovim 并运行健康检查：
```vim
:checkhealth verilog-hierarchy
```

如果所有检查都通过（显示绿色的 OK），说明安装成功！

## 4. 测试功能

1. 打开示例 Verilog 文件：
   ```vim
   :e examples/sample.v
   ```

2. 按下 `<leader>vh` 打开层级窗口（LazyVim 中 leader 默认是空格键，所以是 `空格 + v + h`）

3. 你应该看到一个侧边栏显示模块的所有实例化

4. 使用 `j`/`k` 移动光标，按 `<CR>` (回车) 跳转到实例化位置

5. 按 `q` 或 `<Esc>` 关闭层级窗口

## 5. 在实际项目中使用

1. 打开任何 Verilog 文件 (`.v` 或 `.sv`)

2. 使用快捷键或命令：
   - `<leader>vh` - 切换层级窗口
   - `:VerilogHierarchyToggle` - 命令方式切换

3. 在层级窗口中：
   - `<CR>` - 跳转到实例化
   - `q` 或 `<Esc>` - 关闭窗口

## 6. 自定义配置

你可以在配置文件中修改：

```lua
require("verilog-hierarchy").setup({
  window = {
    width = 50,              -- 调整窗口宽度
    position = "right",      -- 改为右侧显示
  },
  keybindings = {
    toggle = "<leader>vt",   -- 自定义快捷键
  },
  display = {
    icons = {
      module = "📦 ",        -- 自定义图标
      instance = "🔗 ",
    },
  },
})
```

## 7. 常见问题

### Q: 提示 "Treesitter parser for Verilog not found"
A: 运行 `:TSInstall verilog` 安装 Verilog parser

### Q: 提示 "Query file not found"
A: 确保插件正确安装在 runtimepath 中，检查路径设置

### Q: 没有显示任何实例化
A: 确保你的 Verilog 代码中有模块实例化语句，并且语法正确

### Q: 跳转不工作
A: 确保源文件窗口仍然打开，插件需要跳转到源文件

## 8. 工作流建议

1. 使用垂直分割打开多个 Verilog 文件
2. 在主编辑窗口中工作
3. 需要查看层级时按 `<leader>vh`
4. 快速跳转到实例化位置
5. 继续编辑，窗口会自动刷新

## 9. 高级用法

### 在 Lua 脚本中使用

```lua
local vh = require("verilog-hierarchy")

-- 程序化控制
vh.open()
vh.refresh()
vh.close()
```

### 自定义自动命令

```lua
-- 每次进入 Verilog 文件时自动打开层级窗口
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "verilog", "systemverilog" },
  callback = function()
    require("verilog-hierarchy").open()
  end,
})
```

## 需要帮助？

查看 README.md 了解更多详细信息，或在 GitHub 上提交 Issue。
