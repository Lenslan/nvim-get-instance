local M = {}
local config = require('verilog-hierarchy.config')

-- 检查 Tree-sitter 是否可用
function M.is_treesitter_available()
  local ok, _ = pcall(require, 'nvim-treesitter')
  if not ok then return false end
  
  local has_parser = pcall(vim.treesitter.get_parser, 0, 'verilog')
  return has_parser
end

-- 获取节点文本
local function get_node_text(node, bufnr)
  return vim.treesitter.get_node_text(node, bufnr)
end

-- 回退解析方法（使用正则表达式）
function M.fallback_parse(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local instantiations = {}
  
  -- 正则表达式匹配：
  -- 1. 模块类型 (ident)
  -- 2. 可选参数 (#(...))
  -- 3. 实例名称 (ident)
  -- 4. 端口列表 ((...))
  local regex = [[^\s*(\w+)\s*(#\s*\([\s\S]*?\))?\s+(\w+)\s*\([\s\S]*?\)\s*;]]
  
  for i, line in ipairs(lines) do
    -- 简单的单行匹配尝试
    local module_type, _, instance_name = line:match(regex)
    
    -- 如果上面的复杂正则不匹配，尝试更简单的单行匹配
    if not module_type then
        module_type, instance_name = line:match([[^\s*(\w+)\s+()(\w+)\s*%(]])
        -- 修正：Lua pattern 无法完美处理复杂的 Verilog，这里做简单近似
        -- 匹配 "ModuleType u_inst (" 结构
        if not module_type then
           module_type, instance_name = line:match([[^\s*(\w+)\s+(%w+)\s*%(]]) 
        end
    end

    if module_type and instance_name and module_type ~= "module" then
      table.insert(instantiations, {
        module_type = module_type,
        instance_name = instance_name,
        line = i, -- 1-based
        col = 0,  -- 简单起见设为0
        has_params = false -- 正则难以准确判断多行参数
      })
    end
  end
  
  if #instantiations == 0 and #lines > 0 then
      -- 简单的回退：如果没找到，可能是语法太复杂，不做处理
  end

  return instantiations
end

-- 解析当前缓冲区并返回例化列表
function M.parse_instantiations(bufnr)
  bufnr = bufnr or 0
  
  if not config.get('parser.use_treesitter') or not M.is_treesitter_available() then
    if config.get('parser.fallback_regex') then
      return M.fallback_parse(bufnr)
    else
      vim.notify("Verilog Hierarchy: Tree-sitter not available and fallback disabled.", vim.log.levels.ERROR)
      return {}
    end
  end

  local parser = vim.treesitter.get_parser(bufnr, 'verilog')
  local tree = parser:parse()[1]
  local root = tree:root()

  local query_text = [[
    (module_instantiation
      module: (simple_identifier) @module.type
      instance: (name_of_instance
        (instance_identifier) @module.instance)
    ) @instantiation

    (module_instantiation
      module: (simple_identifier) @module.type
      parameter_value_assignment: (_)
      instance: (name_of_instance
        (instance_identifier) @module.instance)
    ) @instantiation
  ]]

  local query = vim.treesitter.query.parse('verilog', query_text)
  local instantiations = {}
  
  -- 遍历匹配
  for _, captures, metadata in query:iter_matches(root, bufnr) do
    local type_node = captures[1] -- @module.type
    local inst_node = captures[2] -- @module.instance (根据查询顺序可能需要调整)
    
    -- 重新映射 captures 以确保正确获取节点，因为 iter_matches 返回列表顺序对应查询定义
    -- 更安全的方法是使用 capture name
    for id, node in pairs(captures) do
      local name = query.captures[id]
      if name == "module.type" then
        type_node = node
      elseif name == "module.instance" then
        inst_node = node
      end
    end

    if type_node and inst_node then
      local type_name = get_node_text(type_node, bufnr)
      local inst_name = get_node_text(inst_node, bufnr)
      local row, col, _, _ = inst_node:range()
      
      -- 检测是否有参数
      local has_params = false
      local parent = type_node:parent()
      if parent then
          for child in parent:iter_children() do
              if child:type() == 'parameter_value_assignment' then
                  has_params = true
                  break
              end
          end
      end

      table.insert(instantiations, {
        module_type = type_name,
        instance_name = inst_name,
        line = row + 1, -- 转换为 1-based
        col = col,
        has_params = has_params
      })
    end
  end

  return instantiations
end

return M