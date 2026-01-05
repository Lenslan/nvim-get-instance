; Tree-sitter 查询文件 - 匹配 Verilog 模块例化

; 匹配简单模块例化
; 格式: module_type instance_name (port_connections);
(module_instantiation
  module: (simple_identifier) @module.type
  instance: (name_of_instance
    (instance_identifier) @module.instance)
) @instantiation

; 匹配带参数的模块例化
; 格式: module_type #(parameters) instance_name (port_connections);
(module_instantiation
  module: (simple_identifier) @module.type
  parameter_value_assignment: (_)
  instance: (name_of_instance
    (instance_identifier) @module.instance)
) @instantiation
