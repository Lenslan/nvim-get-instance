// 示例 Verilog 文件 - 用于测试插件功能

module top (
  input wire clk,
  input wire rst_n,
  input wire [7:0] data_in,
  output wire [15:0] data_out
);

  // 内部信号
  wire [7:0] adder_out;
  wire [7:0] mult_out;
  wire [15:0] regfile_out;
  
  // 简单例化（不带参数）
  adder u_adder (
    .clk(clk),
    .a(data_in),
    .b(8'h01),
    .sum(adder_out)
  );
  
  // 参数化例化
  multiplier #(
    .WIDTH(8),
    .SIGNED(0)
  ) u_mult (
    .clk(clk),
    .rst_n(rst_n),
    .a(adder_out),
    .b(8'h02),
    .product(mult_out)
  );
  
  // 另一个参数化例化
  register_file #(
    .DATA_WIDTH(16),
    .DEPTH(16),
    .ADDR_WIDTH(4)
  ) u_regfile (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(1'b1),
    .wr_addr(4'h0),
    .wr_data({mult_out, mult_out}),
    .rd_addr(4'h0),
    .rd_data(regfile_out)
  );
  
  // 多个相同模块的例化
  mux2to1 u_mux0 (
    .sel(rst_n),
    .in0(regfile_out[7:0]),
    .in1(regfile_out[15:8]),
    .out(data_out[7:0])
  );
  
  mux2to1 u_mux1 (
    .sel(~rst_n),
    .in0(8'h00),
    .in1(8'hFF),
    .out(data_out[15:8])
  );

endmodule

// 子模块定义（用于测试跳转功能）
module adder (
  input wire clk,
  input wire [7:0] a,
  input wire [7:0] b,
  output reg [7:0] sum
);
  always @(posedge clk) begin
    sum <= a + b;
  end
endmodule

module multiplier #(
  parameter WIDTH = 8,
  parameter SIGNED = 0
) (
  input wire clk,
  input wire rst_n,
  input wire [WIDTH-1:0] a,
  input wire [WIDTH-1:0] b,
  output reg [WIDTH-1:0] product
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      product <= {WIDTH{1'b0}};
    else
      product <= a * b;
  end
endmodule
