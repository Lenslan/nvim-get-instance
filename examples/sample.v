// Sample Verilog file for testing verilog-hierarchy plugin
// This file demonstrates various module instantiation patterns

module top_module (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out,
    output wire ready
);

    wire [7:0] processed_data;
    wire valid;
    wire [15:0] intermediate;

    // Simple instantiation
    data_processor proc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(processed_data),
        .valid(valid)
    );

    // Instantiation with parameters
    fifo #(
        .WIDTH(8),
        .DEPTH(16)
    ) fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_data(processed_data),
        .wr_en(valid),
        .rd_data(data_out),
        .full(),
        .empty()
    );

    // Multiple instances of the same module
    register reg_stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .d(data_in),
        .q(intermediate[7:0])
    );

    register reg_stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .d(processed_data),
        .q(intermediate[15:8])
    );

    // Instantiation with array
    output_controller ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data(intermediate),
        .ready(ready)
    );

endmodule

// Supporting modules for demonstration
module data_processor (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out,
    output reg valid
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'h0;
            valid <= 1'b0;
        end else begin
            data_out <= data_in + 8'h1;
            valid <= 1'b1;
        end
    end
endmodule

module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
) (
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] wr_data,
    input wire wr_en,
    output wire [WIDTH-1:0] rd_data,
    output wire full,
    output wire empty
);
    // FIFO implementation here
    assign rd_data = wr_data;
    assign full = 1'b0;
    assign empty = 1'b1;
endmodule

module register (
    input wire clk,
    input wire rst_n,
    input wire [7:0] d,
    output reg [7:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 8'h0;
        else
            q <= d;
    end
endmodule

module output_controller (
    input wire clk,
    input wire rst_n,
    input wire [15:0] data,
    output reg ready
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ready <= 1'b0;
        else
            ready <= |data;
    end
endmodule
