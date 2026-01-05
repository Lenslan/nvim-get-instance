# 需求文档

## 简介

Verilog 层级导航器是一个 Neovim 插件，用于帮助芯片设计工程师快速查看和导航 Verilog 模块的例化层级关系。该插件利用 LSP 和 Tree-sitter 解析 Verilog 代码，提供直观的模块例化列表，并支持快速跳转到例化位置。

## 术语表

- **Plugin**: Neovim 插件，提供 Verilog 层级导航功能
- **Current_Module**: 当前光标所在文件中定义的 Verilog 模块
- **Instantiated_Module**: 在当前模块中被例化的子模块
- **Hierarchy_View**: 显示模块例化关系的浮动窗口或缓冲区
- **LSP**: Language Server Protocol，用于代码分析和导航
- **Tree_sitter**: 代码解析器，用于语法分析

## 需求

### 需求 1: 显示模块例化列表

**用户故事:** 作为芯片设计工程师，我想查看当前模块的所有例化模块，以便快速了解模块的层级结构。

#### 验收标准

1. WHEN 用户在 Verilog 文件中按下配置的快捷键，THEN THE Plugin SHALL 解析当前文件并提取所有模块例化信息
2. WHEN 解析完成后，THEN THE Plugin SHALL 在浮动窗口或分屏中显示例化模块列表
3. WHEN 显示例化列表时，THEN THE Plugin SHALL 包含例化模块名称、例化实例名称和所在行号
4. WHEN 当前文件中没有例化模块时，THEN THE Plugin SHALL 显示提示信息表明没有找到例化
5. WHEN 当前文件不是有效的 Verilog 文件时，THEN THE Plugin SHALL 显示错误提示

### 需求 2: 快速跳转到例化位置

**用户故事:** 作为芯片设计工程师，我想从例化列表直接跳转到代码中的例化位置，以便快速查看和编辑例化代码。

#### 验收标准

1. WHEN 用户在层级视图中选择一个例化模块并按下回车键，THEN THE Plugin SHALL 将光标跳转到该例化在源文件中的行
2. WHEN 跳转完成后，THEN THE Plugin SHALL 关闭层级视图窗口
3. WHEN 跳转完成后，THEN THE Plugin SHALL 将光标定位到例化语句的开始位置
4. WHEN 用户在层级视图中按下 ESC 或 q 键，THEN THE Plugin SHALL 关闭层级视图而不进行跳转

### 需求 3: 利用 Tree-sitter 解析 Verilog 代码

**用户故事:** 作为开发者，我想利用 Tree-sitter 解析 Verilog 代码，以便准确识别模块例化语句。

#### 验收标准

1. WHEN 解析 Verilog 文件时，THEN THE Plugin SHALL 使用 Tree-sitter 查询来识别模块例化节点
2. WHEN 识别例化节点时，THEN THE Plugin SHALL 提取模块类型名称、实例名称和行号信息
3. WHEN Tree-sitter 解析失败时，THEN THE Plugin SHALL 回退到基于正则表达式的简单解析方法
4. WHEN 处理包含参数化例化的模块时，THEN THE Plugin SHALL 正确识别并显示这些例化

### 需求 4: 集成 LSP 功能

**用户故事:** 作为芯片设计工程师，我想利用 LSP 提供的符号信息，以便获得更准确的模块定义位置。

#### 验收标准

1. WHERE LSP 服务可用，WHEN 用户选择跳转到模块定义时，THEN THE Plugin SHALL 使用 LSP 的 "go to definition" 功能
2. WHERE LSP 服务不可用，WHEN 用户尝试跳转时，THEN THE Plugin SHALL 使用基于文件搜索的回退方法
3. WHEN 使用 LSP 查询符号时，THEN THE Plugin SHALL 处理 LSP 超时或错误情况

### 需求 5: 可配置的快捷键和显示选项

**用户故事:** 作为 Neovim 用户，我想自定义快捷键和显示选项，以便插件符合我的工作流程。

#### 验收标准

1. WHEN 插件初始化时，THEN THE Plugin SHALL 提供默认快捷键配置
2. WHEN 用户在配置文件中自定义快捷键时，THEN THE Plugin SHALL 使用用户定义的快捷键
3. WHEN 用户配置显示选项时，THEN THE Plugin SHALL 支持选择浮动窗口或分屏显示模式
4. WHEN 用户配置显示格式时，THEN THE Plugin SHALL 支持自定义列表项的显示格式

### 需求 6: 层级视图交互

**用户故事:** 作为芯片设计工程师，我想在层级视图中进行高效的键盘操作，以便快速浏览和选择例化模块。

#### 验收标准

1. WHEN 层级视图打开时，THEN THE Plugin SHALL 支持使用 j/k 或方向键上下移动选择
2. WHEN 用户按下回车键时，THEN THE Plugin SHALL 跳转到选中的例化位置
3. WHEN 用户按下 ESC 或 q 键时，THEN THE Plugin SHALL 关闭层级视图
4. WHEN 层级视图中有多个例化时，THEN THE Plugin SHALL 高亮显示当前选中的项
5. WHEN 层级视图打开时，THEN THE Plugin SHALL 自动将焦点设置到第一个例化项

### 需求 7: 错误处理和用户反馈

**用户故事:** 作为用户，我想在出现错误时获得清晰的反馈信息，以便了解问题所在。

#### 验收标准

1. WHEN 解析过程中发生错误时，THEN THE Plugin SHALL 在状态栏或通知区域显示错误消息
2. WHEN 找不到例化模块时，THEN THE Plugin SHALL 显示友好的提示信息
3. WHEN Tree-sitter 或 LSP 不可用时，THEN THE Plugin SHALL 提示用户检查配置
4. WHEN 跳转失败时，THEN THE Plugin SHALL 显示具体的失败原因
