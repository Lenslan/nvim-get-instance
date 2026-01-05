-- 快速测试脚本 - 验证插件基本功能
-- 使用方法: nvim -u scripts/test_plugin.lua examples/sample.v

-- 设置 runtimepath
vim.opt.runtimepath:prepend(vim.fn.getcwd())

-- 加载插件
local ok, verilog_hierarchy = pcall(require, 'verilog-hierarchy')
if not ok then
  print("❌ 加载插件失败")
  vim.cmd('quit')
  return
end

print("✅ 插件加载成功")

-- 初始化插件
verilog_hierarchy.setup({
  keymaps = {
    show_hierarchy = '<leader>vh',
    jump_to_def = '<leader>vd',
  },
})

print("✅ 插件初始化成功")

-- 测试配置模块
local config = require('verilog-hierarchy.config')
assert(config.get('ui.window_type') == 'float', "配置测试失败")
print("✅ 配置模块测试通过")

-- 测试解析器模块
local parser = require('verilog-hierarchy.parser')
print("✅ 解析器模块加载成功")

-- 如果打开了文件，尝试解析
vim.defer_fn(function()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  
  if filetype == 'verilog' or filetype == 'systemverilog' then
    print("📄 检测到 Verilog 文件")
    
    local instantiations, err = parser.parse_instantiations(bufnr)
    
    if err then
      print("⚠️  解析错误: " .. err)
    elseif instantiations and #instantiations > 0 then
      print("✅ 找到 " .. #instantiations .. " 个模块例化:")
      for i, inst in ipairs(instantiations) do
        print(string.format("  %d. [%d] %s %s", 
          i, inst.line, inst.module_type, inst.instance_name))
      end
    else
      print("ℹ️  未找到模块例化")
    end
  else
    print("ℹ️  当前文件不是 Verilog 文件")
  end
  
  print("\n🎉 所有测试完成！")
  print("\n使用方法:")
  print("  - 按 <leader>vh 显示模块层级")
  print("  - 按 <leader>vd 跳转到模块定义")
  print("  - 或运行 :VerilogHierarchy 命令")
end, 100)
