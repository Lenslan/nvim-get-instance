# LazyVim 完整配置指南

## 方法 1: 本地插件开发模式（推荐用于测试）

如果你想在本地开发或测试插件，在 `~/.config/nvim/lua/plugins/` 目录下创建文件 `verilog-hierarchy.lua`：

```lua
-- ~/.config/nvim/lua/plugins/verilog-hierarchy.lua

return {
  {
    -- 使用本地路径
    dir = "D:/other-proj/nvim-get-instance",  -- 修改为你的实际路径

    name = "verilog-hierarchy.nvim",

    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },

    -- 只在 Verilog 文件类型时加载（延迟加载）
    ft = { "verilog", "systemverilog" },

    config = function()
      require("verilog-hierarchy").setup({
        window = {
          width = 40,
          position = "left",  -- "left" 或 "right"
        },
        keybindings = {
          toggle = "<leader>vh",
          jump = "<CR>",
          close = "q",
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

    -- 为 which-key 提供键绑定描述
    keys = {
      { "<leader>vh", desc = "Toggle Verilog Hierarchy" },
    },
  },

  -- 确保 Verilog parser 已安装
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- 确保 opts.ensure_installed 存在
      opts.ensure_installed = opts.ensure_installed or {}
      -- 添加 verilog 到自动安装列表
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "verilog" })
      end
    end,
  },
}
```

## 方法 2: 从 GitHub 安装（发布后使用）

```lua
-- ~/.config/nvim/lua/plugins/verilog-hierarchy.lua

return {
  {
    "your-username/verilog-hierarchy.nvim",  -- 替换为实际的 GitHub 路径

    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },

    ft = { "verilog", "systemverilog" },

    config = function()
      require("verilog-hierarchy").setup()
    end,

    keys = {
      { "<leader>vh", desc = "Toggle Verilog Hierarchy" },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "verilog" })
      end
    end,
  },
}
```

## 方法 3: 添加额外的 Which-Key 映射

如果你使用 which-key 并想要更详细的描述：

```lua
-- ~/.config/nvim/lua/plugins/verilog-hierarchy.lua

return {
  {
    dir = "D:/other-proj/nvim-get-instance",
    ft = { "verilog", "systemverilog" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("verilog-hierarchy").setup()
    end,
  },

  -- Which-Key 集成
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      defaults = {
        ["<leader>v"] = { name = "+verilog" },
      },
    },
  },
}
```

## 安装步骤

1. **创建配置文件**
   ```bash
   # Windows
   mkdir -p ~/.config/nvim/lua/plugins
   # 然后创建 verilog-hierarchy.lua 文件
   ```

2. **重启 Neovim**
   ```bash
   nvim
   ```
   LazyVim 会自动检测新插件并加载

3. **安装 Verilog Parser**
   ```vim
   :TSInstall verilog
   ```

4. **验证安装**
   ```vim
   :checkhealth verilog-hierarchy
   ```

## 测试插件

1. 打开示例文件：
   ```bash
   cd D:/other-proj/nvim-get-instance
   nvim examples/sample.v
   ```

2. 在 Neovim 中按 `<Space>vh` (默认 leader 是空格)

3. 应该会在左侧看到层级窗口

## 自定义配置示例

### 配置 1: 右侧显示，更宽的窗口

```lua
require("verilog-hierarchy").setup({
  window = {
    width = 60,
    position = "right",
  },
})
```

### 配置 2: 自定义图标和快捷键

```lua
require("verilog-hierarchy").setup({
  keybindings = {
    toggle = "<leader>vt",  -- 改为 vt
  },
  display = {
    icons = {
      module = "📦 ",
      instance = "🔗 ",
    },
  },
})
```

### 配置 3: 最小配置（使用所有默认值）

```lua
require("verilog-hierarchy").setup()
```

## 与其他插件集成

### 与 Neo-tree 一起使用

```lua
{
  dir = "D:/other-proj/nvim-get-instance",
  ft = { "verilog", "systemverilog" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("verilog-hierarchy").setup({
      window = {
        position = "right",  -- Neo-tree 在左边，层级在右边
      },
    })
  end,
}
```

### 与 Telescope 一起使用

可以创建自定义命令快速打开：

```lua
vim.keymap.set("n", "<leader>fv", function()
  require("verilog-hierarchy").toggle()
end, { desc = "Find Verilog Hierarchy" })
```

## 工作流建议

### 推荐的窗口布局

```
┌─────────────────────────────────────────────────────────┐
│  Neo-tree     │  Main Editor   │  Verilog Hierarchy    │
│  (文件树)      │  (编辑区)       │  (层级窗口)             │
│               │                │                        │
│               │                │  → proc_inst           │
│               │                │    Type: data_proc     │
│               │                │                        │
│               │                │  → fifo_inst           │
│               │                │    Type: fifo          │
└─────────────────────────────────────────────────────────┘
```

### 推荐的快捷键

- `<leader>e` - 切换 Neo-tree (LazyVim 默认)
- `<leader>vh` - 切换 Verilog Hierarchy (本插件)
- `<leader>ff` - Telescope 查找文件 (LazyVim 默认)

## 故障排除

### 问题: 插件没有加载

检查：
```vim
:Lazy
```
查找 verilog-hierarchy，确保状态正常

### 问题: Parser 错误

重新安装 parser：
```vim
:TSUninstall verilog
:TSInstall verilog
```

### 问题: 快捷键冲突

修改配置使用不同的键：
```lua
keybindings = {
  toggle = "<leader>vH",  -- 使用大写 H
}
```

### 问题: 窗口显示异常

尝试刷新：
```vim
:VerilogHierarchyRefresh
```

## 卸载

如果需要移除插件：

1. 删除配置文件：
   ```bash
   rm ~/.config/nvim/lua/plugins/verilog-hierarchy.lua
   ```

2. 重启 Neovim，Lazy 会自动清理

## 更新插件

### 本地开发模式

直接编辑源代码后重启 Neovim

### GitHub 模式

```vim
:Lazy update verilog-hierarchy.nvim
```

## 获取帮助

- 查看 `:help verilog-hierarchy` (TODO: 添加帮助文档)
- 运行 `:checkhealth verilog-hierarchy`
- 查看 GitHub Issues
