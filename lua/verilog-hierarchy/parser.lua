-- parser.lua - Tree-sitter 解析器模块
local M = {}

-- 检查 Tree-sitter 是否可用
-- @return boolean: Tree-sitter 是否已安装并可用
function M.is_treesitter_available()
  local ok, _ = pcall(require, 'nvim-treesitter')
  if not ok then
    return false
  end
  
  -- 检查是否有 verilog parser
  local has_parser = pcall(vim.treesitter.get_parser, 0, 'verilog')
  return has_parser
end

-- 使用 Tree-sitter 解析例化
-- @param bufnr number: 缓冲区编号
-- @return table: 例化信息列表
local function parse_with_treesitter(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, 'verilog')
  local tree = parser:parse()[1]
  local root = tree:root()
  
  -- Tree-sitter 查询字符串
  local query_string = [[
    (module_instantiation
      module: (simple_identifier) @module.type
      instance: (name_of_instance
        (instance_identifier) @module.instance)
    ) @instantiation
  ]]
  
  local ok, query = pcall(vim.treesitter.query.parse, 'verilog', query_string)
  if not ok then
    return nil
  end
  
  local instantiations = {}
  
  for id, node, _ in query:iter_captures(root, bufnr, 0, -1) do
    local capture_name = query.captures[id]
    
    if capture_name == 'instantiation' then
      local module_type = nil
      local instance_name = nil
      local line, col = node:start()
      
      -- 提取模块类型和实例名称
      for child_id, child_node, _ in query:iter_captures(node, bufnr, 0, -1) do
        local child_capture = query.captures[child_id]
        if child_capture == 'module.type' then
          module_type = vim.treesitter.get_node_text(child_node, bufnr)
        elseif child_capture == 'module.instance' then
          instance_name = vim.treesitter.get_node_text(child_node, bufnr)
        end
      end
      
      if module_type and instance_name then
        table.insert(instantiations, {
          module_type = module_type,
          instance_name = instance_name,
          line = line + 1,  -- 转换为 1-based
          col = col,
        })
      end
    end
  end
  
  return instantiations
end

-- 回退解析方法（使用正则表达式）
-- @param bufnr number: 缓冲区编号
-- @return table: 例化信息列表
function M.fallback_parse(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local instantiations = {}
  
  -- 匹配模块例化的正则表达式
  -- 格式: module_type [#(params)] instance_name (ports);
  local pattern = '(%w+)%s*[#%(].*%s+(%w+)%s*%('
  
  for line_num, line in ipairs(lines) do
    -- 跳过注释行
    if not line:match('^%s*//') and not line:match('^%s*%*') then
      local module_type, instance_name = line:match(pattern)
      
      if module_type and instance_name then
        -- 过滤掉 Verilog 关键字
        local keywords = {
          'module', 'endmodule', 'input', 'output', 'inout', 
          'wire', 'reg', 'always', 'initial', 'if', 'else', 'case'
        }
        
        local is_keyword = false
        for _, kw in ipairs(keywords) do
          if module_type == kw then
            is_keyword = true
            break
          end
        end
        
        if not is_keyword then
          table.insert(instantiations, {
            module_type = module_type,
            instance_name = instance_name,
            line = line_num,
            col = 0,
          })
        end
      end
    end
  end
  
  return instantiations
end

-- 解析当前缓冲区并返回例化列表
-- @param bufnr number: 缓冲区编号
-- @return table: 例化信息列表，每项包含 {module_type, instance_name, line, col}
function M.parse_instantiations(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  -- 检查是否是 Verilog 文件
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  if filetype ~= 'verilog' and filetype ~= 'systemverilog' then
    return nil, "Not a Verilog file"
  end
  
  local instantiations = nil
  local error_msg = nil
  
  -- 尝试使用 Tree-sitter
  if M.is_treesitter_available() then
    local ok, result = pcall(parse_with_treesitter, bufnr)
    if ok and result then
      instantiations = result
    else
      error_msg = "Tree-sitter parsing failed"
    end
  end
  
  -- 回退到正则表达式解析
  if not instantiations then
    local config = require('verilog-hierarchy.config')
    if config.get('parser.fallback_regex') then
      instantiations = M.fallback_parse(bufnr)
      if error_msg then
        vim.notify("Tree-sitter not available, using fallback parser", vim.log.levels.WARN)
      end
    else
      return nil, error_msg or "Tree-sitter not available and fallback disabled"
    end
  end
  
  return instantiations, nil
end

return M
