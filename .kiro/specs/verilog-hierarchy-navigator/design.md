# 设计文档

## 概述

Verilog 层级导航器是一个 Neovim Lua 插件，用于解析和显示 Verilog 模块的例化层级关系。该插件利用 Tree-sitter 进行语法分析，使用 Neovim 的浮动窗口 API 显示交互式列表，并支持通过 LSP 进行精确的代码导航。

插件的核心功能包括：
- 使用 Tree-sitter 查询提取模块例化信息
- 在浮动窗口中显示例化列表
- 支持键盘导航和快速跳转
- 与 LSP 集成以获得更准确的符号定义位置

## 架构

插件采用模块化架构，分为以下几个主要组件：

```
verilog-hierarchy-navigator/
├── lua/
│   └── verilog-hierarchy/
│       ├── init.lua           # 插件入口和配置
│       ├── parser.lua          # Tree-sitter 解析器
│       ├── ui.lua              # 浮动窗口和用户界面
│       ├── navigator.lua       # 跳转和导航逻辑
│       └── config.lua          # 配置管理
└── queries/
    └── verilog/
        └── instantiations.scm  # Tree-sitter 查询定义
```

### 组件交互流程

1. 用户按下快捷键触发插件
2. `parser.lua` 使用 Tree-sitter 解析当前缓冲区
3. 提取的例化信息传递给 `ui.lua`
4. `ui.lua` 创建浮动窗口并显示列表
5. 用户选择例化项后，`navigator.lua` 执行跳转

## 组件和接口

### 1. Parser 模块 (parser.lua)

负责使用 Tree-sitter 解析 Verilog 代码并提取模块例化信息。

#### 接口

```lua
-- 解析当前缓冲区并返回例化列表
-- @param bufnr number: 缓冲区编号
-- @return table: 例化信息列表，每项包含 {module_type, instance_name, line, col}
function M.parse_instantiations(bufnr)

-- 检查 Tree-sitter 是否可用
-- @return boolean: Tree-sitter 是否已安装并可用
function M.is_treesitter_available()

-- 回退解析方法（使用正则表达式）
-- @param bufnr number: 缓冲区编号
-- @return table: 例化信息列表
function M.fallback_parse(bufnr)
```

#### Tree-sitter 查询

Verilog 模块例化的典型语法：
```verilog
module_type #(parameters) instance_name (port_connections);
```

Tree-sitter 查询模式（queries/verilog/instantiations.scm）：
```scheme
; 匹配模块例化
(module_instantiation
  module: (simple_identifier) @module.type
  instance: (name_of_instance
    (instance_identifier) @module.instance)
) @instantiation

; 匹配带参数的模块例化
(module_instantiation
  module: (simple_identifier) @module.type
  parameter_value_assignment: (_)
  instance: (name_of_instance
    (instance_identifier) @module.instance)
) @instantiation
```

### 2. UI 模块 (ui.lua)

负责创建和管理浮动窗口，显示例化列表并处理用户交互。

#### 接口

```lua
-- 创建并显示浮动窗口
-- @param instantiations table: 例化信息列表
-- @param on_select function: 选择回调函数
-- @return number, number: 窗口 ID 和缓冲区 ID
function M.show_hierarchy(instantiations, on_select)

-- 关闭浮动窗口
function M.close_window()

-- 设置窗口键盘映射
-- @param bufnr number: 缓冲区编号
-- @param on_select function: 选择回调函数
function M.setup_keymaps(bufnr, on_select)
```

#### 浮动窗口配置

使用 `vim.api.nvim_open_win()` 创建浮动窗口：

```lua
local config = {
  relative = 'editor',
  width = math.floor(vim.o.columns * 0.6),
  height = math.min(#instantiations + 2, math.floor(vim.o.lines * 0.5)),
  row = math.floor(vim.o.lines * 0.2),
  col = math.floor(vim.o.columns * 0.2),
  style = 'minimal',
  border = 'rounded',
  title = ' Module Instantiations ',
  title_pos = 'center'
}
```

#### 显示格式

每个例化项的显示格式：
```
[行号] 模块类型 实例名称
```

示例：
```
[15] adder u_adder_0
[23] multiplier u_mult
[45] register_file u_regfile
```

### 3. Navigator 模块 (navigator.lua)

负责处理跳转逻辑，包括跳转到例化位置和使用 LSP 跳转到模块定义。

#### 接口

```lua
-- 跳转到指定行和列
-- @param line number: 目标行号（1-based）
-- @param col number: 目标列号（0-based）
function M.jump_to_location(line, col)

-- 使用 LSP 跳转到模块定义
-- @param module_type string: 模块类型名称
-- @return boolean: 是否成功跳转
function M.jump_to_definition(module_type)

-- 检查 LSP 是否可用
-- @return boolean: LSP 是否已连接
function M.is_lsp_available()
```

### 4. Config 模块 (config.lua)

管理插件配置和用户自定义选项。

#### 接口

```lua
-- 默认配置
M.defaults = {
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
    border = 'rounded',     -- 边框样式
  },
  
  -- 解析器配置
  parser = {
    use_treesitter = true,  -- 优先使用 Tree-sitter
    fallback_regex = true,  -- 启用正则表达式回退
  },
}

-- 设置用户配置
-- @param opts table: 用户配置选项
function M.setup(opts)

-- 获取配置值
-- @param key string: 配置键（支持点号分隔的路径）
-- @return any: 配置值
function M.get(key)
```

### 5. Init 模块 (init.lua)

插件入口点，负责初始化和注册命令。

#### 接口

```lua
-- 初始化插件
-- @param opts table: 用户配置选项
function M.setup(opts)

-- 显示当前模块的层级关系
function M.show_hierarchy()

-- 跳转到模块定义
function M.jump_to_definition()
```

## 数据模型

### Instantiation 对象

表示一个模块例化的数据结构：

```lua
{
  module_type = "adder",      -- 模块类型名称
  instance_name = "u_adder_0", -- 实例名称
  line = 15,                   -- 行号（1-based）
  col = 4,                     -- 列号（0-based）
  has_params = false,          -- 是否有参数化
}
```

### Configuration 对象

插件配置的数据结构：

```lua
{
  keymaps = {
    show_hierarchy = "<leader>vh",
    jump_to_def = "<leader>vd",
  },
  ui = {
    window_type = "float",
    width_ratio = 0.6,
    height_ratio = 0.5,
    border = "rounded",
  },
  parser = {
    use_treesitter = true,
    fallback_regex = true,
  },
}
```

## 正确性属性

*属性是关于系统行为的特征或规则，应该在所有有效执行中保持为真。属性是人类可读规范和机器可验证正确性保证之间的桥梁。*


### 属性 1: 解析提取完整性
*对于任何* 包含模块例化的 Verilog 代码，解析后提取的例化信息应该包含所有例化的模块类型名称、实例名称和行号，且信息应该准确对应源代码中的例化语句。
**验证需求: 1.1, 3.2**

### 属性 2: 显示内容格式正确性
*对于任何* 例化信息列表，在浮动窗口中显示时，每个列表项应该包含行号、模块类型名称和实例名称，且格式应该一致可读。
**验证需求: 1.2, 1.3**

### 属性 3: 参数化例化识别
*对于任何* 包含参数化例化的 Verilog 模块，解析器应该正确识别这些例化，无论参数列表的复杂程度如何。
**验证需求: 3.4**

### 属性 4: 跳转位置准确性
*对于任何* 选中的例化项，执行跳转后光标应该定位到该例化在源文件中的准确位置（正确的行和列），且层级视图窗口应该被关闭。
**验证需求: 2.1, 2.2, 2.3, 6.2**

### 属性 5: 取消操作保持状态
*对于任何* 打开的层级视图，当用户按下取消键（ESC 或 q）时，窗口应该关闭且光标位置应该保持不变。
**验证需求: 2.4, 6.3**

### 属性 6: 配置合并正确性
*对于任何* 用户提供的配置选项，插件应该正确合并用户配置和默认配置，用户配置应该覆盖默认值，未指定的选项应该使用默认值。
**验证需求: 5.2, 5.3, 5.4**

### 属性 7: 错误消息提供性
*对于任何* 解析错误或跳转失败的情况，插件应该向用户显示清晰的错误消息，说明失败的具体原因。
**验证需求: 7.1, 7.4**

## 错误处理

### 解析错误

1. **Tree-sitter 不可用**
   - 检测：调用 `vim.treesitter.get_parser()` 时捕获异常
   - 处理：回退到正则表达式解析方法
   - 用户反馈：显示警告信息 "Tree-sitter not available, using fallback parser"

2. **无效的 Verilog 语法**
   - 检测：Tree-sitter 解析返回错误节点
   - 处理：尝试部分解析，提取可识别的例化
   - 用户反馈：显示警告 "File contains syntax errors, results may be incomplete"

3. **空文件或无例化**
   - 检测：解析结果为空列表
   - 处理：正常流程，不视为错误
   - 用户反馈：显示信息 "No module instantiations found in current file"

### 导航错误

1. **LSP 不可用**
   - 检测：`vim.lsp.get_active_clients()` 返回空列表
   - 处理：使用基于文件搜索的回退方法
   - 用户反馈：静默回退，不显示错误

2. **LSP 超时**
   - 检测：LSP 请求超过 5 秒未响应
   - 处理：取消请求，使用回退方法
   - 用户反馈：显示警告 "LSP timeout, using fallback navigation"

3. **跳转目标不存在**
   - 检测：目标行号超出文件范围
   - 处理：跳转到文件末尾
   - 用户反馈：显示错误 "Target location not found"

### UI 错误

1. **窗口创建失败**
   - 检测：`nvim_open_win()` 返回错误
   - 处理：尝试使用分屏模式
   - 用户反馈：显示错误 "Failed to create floating window"

2. **缓冲区操作失败**
   - 检测：缓冲区 API 调用异常
   - 处理：清理资源，关闭窗口
   - 用户反馈：显示错误 "Buffer operation failed"

## 测试策略

### 单元测试

使用 [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) 测试框架进行单元测试。

**测试覆盖范围：**

1. **Parser 模块**
   - 测试简单模块例化的解析
   - 测试参数化模块例化的解析
   - 测试多个例化的解析
   - 测试空文件的处理
   - 测试回退解析器

2. **UI 模块**
   - 测试浮动窗口创建
   - 测试列表项格式化
   - 测试键盘映射设置
   - 测试窗口关闭

3. **Navigator 模块**
   - 测试跳转到指定位置
   - 测试 LSP 可用性检查
   - 测试跳转失败处理

4. **Config 模块**
   - 测试默认配置
   - 测试配置合并
   - 测试配置获取

**示例单元测试：**

```lua
describe("parser", function()
  it("should parse simple module instantiation", function()
    local content = [[
module top;
  adder u_adder(.a(a), .b(b), .sum(sum));
endmodule
]]
    local result = parser.parse_instantiations(content)
    assert.equals(1, #result)
    assert.equals("adder", result[1].module_type)
    assert.equals("u_adder", result[1].instance_name)
  end)
end)
```

### 基于属性的测试

使用 Lua 的属性测试库（如自定义实现或移植的 QuickCheck）进行属性测试。

**测试配置：**
- 每个属性测试运行最少 100 次迭代
- 使用随机生成的 Verilog 代码片段
- 每个测试标记对应的设计属性

**属性测试实现：**

1. **属性 1: 解析提取完整性**
   - 生成器：随机生成包含 1-10 个例化的 Verilog 代码
   - 验证：解析结果数量等于生成的例化数量，且每个例化信息正确
   - 标签：**Feature: verilog-hierarchy-navigator, Property 1: 解析提取完整性**

2. **属性 2: 显示内容格式正确性**
   - 生成器：随机生成例化信息列表
   - 验证：格式化后的每行包含行号、模块类型和实例名称
   - 标签：**Feature: verilog-hierarchy-navigator, Property 2: 显示内容格式正确性**

3. **属性 3: 参数化例化识别**
   - 生成器：随机生成带参数和不带参数的例化
   - 验证：两种类型的例化都被正确识别
   - 标签：**Feature: verilog-hierarchy-navigator, Property 3: 参数化例化识别**

4. **属性 4: 跳转位置准确性**
   - 生成器：随机生成例化位置信息
   - 验证：跳转后光标位置与目标位置一致
   - 标签：**Feature: verilog-hierarchy-navigator, Property 4: 跳转位置准确性**

5. **属性 5: 取消操作保持状态**
   - 生成器：随机生成初始光标位置
   - 验证：取消后光标位置不变
   - 标签：**Feature: verilog-hierarchy-navigator, Property 5: 取消操作保持状态**

6. **属性 6: 配置合并正确性**
   - 生成器：随机生成部分配置选项
   - 验证：合并后的配置包含用户值和默认值
   - 标签：**Feature: verilog-hierarchy-navigator, Property 6: 配置合并正确性**

7. **属性 7: 错误消息提供性**
   - 生成器：随机生成错误场景
   - 验证：每个错误场景都产生非空的错误消息
   - 标签：**Feature: verilog-hierarchy-navigator, Property 7: 错误消息提供性**

### 集成测试

**测试场景：**

1. **完整工作流测试**
   - 打开 Verilog 文件
   - 触发层级显示
   - 选择例化项
   - 验证跳转成功

2. **LSP 集成测试**
   - 启动 Verilog LSP 服务器
   - 测试跳转到定义功能
   - 验证 LSP 响应处理

3. **错误恢复测试**
   - 模拟各种错误场景
   - 验证插件不崩溃
   - 验证错误消息正确显示

### 测试数据生成器

为属性测试创建智能生成器：

```lua
-- Verilog 例化生成器
function generate_instantiation()
  local module_types = {"adder", "multiplier", "register", "mux", "decoder"}
  local module_type = module_types[math.random(#module_types)]
  local instance_name = "u_" .. module_type .. "_" .. math.random(0, 99)
  local has_params = math.random() > 0.5
  
  local inst = module_type
  if has_params then
    inst = inst .. " #(.WIDTH(32))"
  end
  inst = inst .. " " .. instance_name .. "(.clk(clk), .rst(rst));"
  
  return {
    code = inst,
    module_type = module_type,
    instance_name = instance_name,
    has_params = has_params,
  }
end

-- Verilog 模块生成器
function generate_verilog_module(num_instantiations)
  local lines = {"module top;"}
  local instantiations = {}
  
  for i = 1, num_instantiations do
    local inst = generate_instantiation()
    table.insert(lines, "  " .. inst.code)
    table.insert(instantiations, inst)
  end
  
  table.insert(lines, "endmodule")
  
  return {
    code = table.concat(lines, "\n"),
    instantiations = instantiations,
  }
end
```

### 测试执行

**运行测试：**

```bash
# 运行所有单元测试
nvim --headless -c "PlenaryBustedDirectory lua/tests/ {minimal_init = 'tests/minimal_init.lua'}"

# 运行属性测试
nvim --headless -c "lua require('tests.property_tests').run_all()"
```

**持续集成：**

使用 GitHub Actions 在每次提交时自动运行测试：

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install Neovim
        run: |
          wget https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz
          tar xzf nvim-linux64.tar.gz
      - name: Run tests
        run: |
          ./nvim-linux64/bin/nvim --headless -c "PlenaryBustedDirectory lua/tests/"
```

## 实现注意事项

### Tree-sitter 查询优化

- 使用 `vim.treesitter.query.parse()` 预编译查询以提高性能
- 缓存解析结果，避免重复解析同一文件
- 使用增量解析处理大文件

### 性能考虑

- 对于大文件（>1000 行），使用异步解析避免阻塞 UI
- 限制浮动窗口显示的最大例化数量（如 100 个）
- 使用虚拟文本或折叠处理大量例化

### 兼容性

- 支持 Neovim 0.8+ 版本
- 兼容 Verilog-2001 和 SystemVerilog 语法
- 与常见 Verilog LSP 服务器集成（如 verible-verilog-ls, svls）

### 用户体验

- 提供清晰的错误消息和警告
- 支持自定义高亮组以匹配用户配色方案
- 提供详细的文档和使用示例
- 支持中文和英文界面（通过配置）
