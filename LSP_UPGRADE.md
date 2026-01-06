# LSP 升级说明

## 主要变化

插件已从纯 treesitter 实现升级为 **LSP 优先 + Treesitter 备用** 的混合方案。

## 为什么要改用 LSP？

1. **更准确**：LSP 服务器理解代码的语义，而不仅仅是语法
2. **更可靠**：避免了复杂的 treesitter query 匹配问题
3. **更灵活**：不同的 LSP 服务器可以提供更丰富的符号信息
4. **与 nvim-navic 一致**：使用与社区流行插件相同的方法

## 工作原理

### LSP 模式（推荐）

```
Verilog 文件 → LSP 服务器 → documentSymbol API → 解析符号 → 显示层级
```

插件通过 LSP 的 `textDocument/documentSymbol` API 获取文档符号，然后从中提取模块实例化信息。

### Treesitter 备用模式

如果没有 LSP 服务器连接，插件会自动回退到 treesitter 直接解析模式：

```
Verilog 文件 → Treesitter → 遍历语法树 → 查找 module_instantiation 节点 → 显示层级
```

## 需要安装的 LSP 服务器

选择以下之一：

### 1. svls（推荐）

```bash
# 安装
cargo install svls

# LazyVim 配置
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

### 2. verible-verilog-ls

```bash
# 从 https://github.com/chipsalliance/verible/releases 下载

# LazyVim 配置
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        verible = {
          cmd = { "verible-verilog-ls", "--rules_config_search" },
        },
      },
    },
  },
}
```

### 3. hdl_checker

```bash
# 安装
pip install hdl-checker

# LazyVim 配置
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        hdl_checker = {},
      },
    },
  },
}
```

## 调试 LSP 问题

### 1. 检查 LSP 是否连接

```vim
:LspInfo
```

应该看到 Verilog LSP 服务器已连接。

### 2. 运行调试脚本

```vim
:e examples/sample.v
:luafile scripts/debug_lsp_symbols.lua
```

这将显示：
- LSP 客户端信息
- documentSymbol 支持状态
- 返回的所有符号及其类型
- 哪些符号可能是模块实例化

### 3. 检查健康状态

```vim
:checkhealth verilog-hierarchy
```

会检查：
- Neovim 版本
- LSP 支持和连接状态
- Treesitter 备用支持

### 4. 运行完整测试

```vim
:e examples/sample.v
:luafile scripts/test_plugin.lua
```

## 常见问题

### Q: 我的 LSP 已连接但插件显示没有实例化

**A:** 不同的 LSP 服务器可能使用不同的符号类型（SymbolKind）来标记模块实例化。

**解决方案：**
1. 运行 `debug_lsp_symbols.lua` 查看 LSP 返回的符号
2. 检查哪些符号的 `kind` 和 `detail` 字段包含实例化信息
3. 如果发现问题，在 GitHub 上提 issue，附上调试脚本的输出

目前插件支持的符号类型：
- `kind == 8` (Field)
- `kind == 13` (Variable)

如果你的 LSP 使用其他类型，请提 issue。

### Q: 能否同时支持多个 LSP 服务器？

**A:** 插件会使用第一个支持 `documentSymbolProvider` 的 LSP 客户端。如果有多个，它会选择第一个。

### Q: 我不想用 LSP，只用 Treesitter 可以吗？

**A:** 可以！如果没有 LSP 连接，插件会自动使用 treesitter。只需：
```vim
:TSInstall verilog
```

然后打开 Verilog 文件，插件会自动使用 treesitter 模式。

### Q: LSP 模式比 Treesitter 慢吗？

**A:** LSP 请求是异步的，所以不会阻塞编辑器。首次打开可能需要几百毫秒，但后续操作会很快。

## 代码变化摘要

### parser.lua
- ✅ 新增 `get_verilog_lsp_client()` 函数查找 LSP 客户端
- ✅ 新增 `parse_symbols()` 函数解析 LSP 符号
- ✅ 新增 `parse_with_treesitter()` 作为备用
- ✅ 重写 `get_instantiations()` 支持 LSP + callback 模式
- ✅ 优化 `get_current_module()` 使用 treesitter 直接遍历

### navigator.lua
- ✅ 更新 `open()` 和 `refresh()` 函数支持异步回调

### health.lua
- ✅ 新增 LSP 状态检查
- ✅ 将 treesitter 标记为可选（用于备用）

### 新增文件
- ✅ `scripts/debug_lsp_symbols.lua` - LSP 调试工具
- ✅ `scripts/test_plugin.lua` - 完整功能测试

### 文档
- ✅ README.md 更新为 LSP 优先
- ✅ 新增 LSP 服务器安装说明
- ✅ 新增故障排除指南

## 升级建议

对于已经安装旧版本的用户：

1. 安装一个 Verilog LSP 服务器（推荐 svls）
2. 更新插件到最新版本
3. 运行 `:checkhealth verilog-hierarchy` 检查状态
4. 如果一切正常，可以继续使用
5. 如果遇到问题，运行 `debug_lsp_symbols.lua` 查看详情

## 性能对比

| 特性 | LSP 模式 | Treesitter 模式 |
|------|----------|----------------|
| 准确性 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 速度 | 异步，不阻塞 | 同步，稍快 |
| 可靠性 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 配置复杂度 | 需要安装 LSP | 只需 treesitter |
| 额外信息 | 类型、文档等 | 仅语法信息 |

## 未来计划

- [ ] 支持更多 LSP 服务器的符号类型
- [ ] 添加配置选项强制使用特定模式（LSP 或 Treesitter）
- [ ] 缓存 LSP 符号以提高性能
- [ ] 支持跨文件的模块定义跳转
