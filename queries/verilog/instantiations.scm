; Query for Verilog module instantiations
; Captures module_instantiation nodes with module type and instance name

(module_instantiation
  (simple_identifier) @module_type
  (name_of_instance
    instance_name: (simple_identifier) @instance_name)) @instantiation
