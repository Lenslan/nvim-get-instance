-- 解析器模块测试
local parser = require('verilog-hierarchy.parser')

describe("parser module", function()
  
  describe("fallback_parse", function()
    it("should parse simple module instantiation", function()
      -- 创建测试缓冲区
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(buf, 'filetype', 'verilog')
      
      local content = {
        "module top;",
        "  adder u_adder(.a(a), .b(b), .sum(sum));",
        "endmodule"
      }
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
      
      local result = parser.fallback_parse(buf)
      
      assert.equals(1, #result)
      assert.equals("adder", result[1].module_type)
      assert.equals("u_adder", result[1].instance_name)
      assert.equals(2, result[1].line)
      
      -- 清理
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
    
    it("should parse parameterized instantiation", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(buf, 'filetype', 'verilog')
      
      local content = {
        "module top;",
        "  multiplier #(.WIDTH(8)) u_mult(.clk(clk), .a(a));",
        "endmodule"
      }
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
      
      local result = parser.fallback_parse(buf)
      
      assert.equals(1, #result)
      assert.equals("multiplier", result[1].module_type)
      assert.equals("u_mult", result[1].instance_name)
      
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
    
    it("should parse multiple instantiations", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(buf, 'filetype', 'verilog')
      
      local content = {
        "module top;",
        "  adder u_adder(.a(a), .b(b));",
        "  multiplier u_mult(.a(a), .b(b));",
        "  register u_reg(.clk(clk));",
        "endmodule"
      }
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
      
      local result = parser.fallback_parse(buf)
      
      assert.equals(3, #result)
      assert.equals("adder", result[1].module_type)
      assert.equals("multiplier", result[2].module_type)
      assert.equals("register", result[3].module_type)
      
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
    
    it("should skip comment lines", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(buf, 'filetype', 'verilog')
      
      local content = {
        "module top;",
        "  // adder u_adder(.a(a), .b(b));",
        "  multiplier u_mult(.a(a), .b(b));",
        "endmodule"
      }
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
      
      local result = parser.fallback_parse(buf)
      
      assert.equals(1, #result)
      assert.equals("multiplier", result[1].module_type)
      
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
    
    it("should filter out Verilog keywords", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(buf, 'filetype', 'verilog')
      
      local content = {
        "module top;",
        "  wire w1;",
        "  reg r1;",
        "  adder u_adder(.a(a));",
        "endmodule"
      }
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
      
      local result = parser.fallback_parse(buf)
      
      assert.equals(1, #result)
      assert.equals("adder", result[1].module_type)
      
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
    
    it("should return empty list for file with no instantiations", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(buf, 'filetype', 'verilog')
      
      local content = {
        "module top;",
        "  wire a, b, c;",
        "  assign c = a & b;",
        "endmodule"
      }
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
      
      local result = parser.fallback_parse(buf)
      
      assert.equals(0, #result)
      
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)
  
  describe("parse_instantiations", function()
    it("should return error for non-Verilog file", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(buf, 'filetype', 'lua')
      
      local result, err = parser.parse_instantiations(buf)
      
      assert.is_nil(result)
      assert.is_not_nil(err)
      assert.matches("Not a Verilog file", err)
      
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)
end)
