; 匹配普通模块例化
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