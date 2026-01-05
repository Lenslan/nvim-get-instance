-- 配置模块测试
local config = require('verilog-hierarchy.config')

describe("config module", function()
  before_each(function()
    -- 重置配置
    config.options = vim.deepcopy(config.defaults)
  end)
  
  it("should have default configuration", function()
    assert.is_not_nil(config.defaults)
    assert.equals('float', config.defaults.ui.window_type)
    assert.equals(0.6, config.defaults.ui.width_ratio)
    assert.is_true(config.defaults.parser.use_treesitter)
  end)
  
  it("should merge user configuration with defaults", function()
    config.setup({
      ui = {
        width_ratio = 0.8,
      }
    })
    
    assert.equals(0.8, config.get('ui.width_ratio'))
    assert.equals(0.5, config.get('ui.height_ratio'))  -- 保持默认值
    assert.equals('float', config.get('ui.window_type'))  -- 保持默认值
  end)
  
  it("should get nested configuration values", function()
    assert.equals('<leader>vh', config.get('keymaps.show_hierarchy'))
    assert.equals('rounded', config.get('ui.border'))
  end)
  
  it("should return nil for non-existent keys", function()
    assert.is_nil(config.get('non.existent.key'))
  end)
  
  it("should handle deep merge correctly", function()
    config.setup({
      keymaps = {
        show_hierarchy = '<leader>vi',
      },
      ui = {
        border = 'double',
      }
    })
    
    assert.equals('<leader>vi', config.get('keymaps.show_hierarchy'))
    assert.equals('<leader>vd', config.get('keymaps.jump_to_def'))  -- 保持默认
    assert.equals('double', config.get('ui.border'))
    assert.equals(0.6, config.get('ui.width_ratio'))  -- 保持默认
  end)
end)
