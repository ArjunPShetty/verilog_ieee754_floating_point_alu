`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.03.2026 19:58:17
// Design Name: 
// Module Name: fp_alu_top 
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fp_alu_top(
input  wire  clk,
input  wire  rst_n,
input  wire [31:0] op_a,
input  wire [31:0] op_b,
input  wire [1:0]  op_code,
output wire [31:0] result,
output wire ready,
output wire [4:0]  exception
);

wire [31:0] adder_result;
wire [31:0] mult_result;
wire [31:0] div_result;

wire adder_ready;
wire mult_ready;
wire div_ready;

wire [4:0] adder_exc;
wire [4:0] mult_exc;
wire [4:0] div_exc;

reg [31:0] result_reg;
reg ready_reg;
reg [4:0] exc_reg;

reg [31:0] result_mux;
reg ready_mux;
reg [4:0] exc_mux;

fp_adder u_adder(
.clk(clk),
.rst_n(rst_n),
.op_a(op_a),
.op_b(op_b),
.result(adder_result),
.ready(adder_ready),
.exception(adder_exc)
);

fp_multiplier u_mult(
.clk(clk),
.rst_n(rst_n),
.op_a(op_a),
.op_b(op_b),
.result(mult_result),
.ready(mult_ready),
.exception(mult_exc)
);

fp_divider u_div(
.clk(clk),
.rst_n(rst_n),
.op_a(op_a),
.op_b(op_b),
.result(div_result),
.ready(div_ready),
.exception(div_exc)
);

always @(*) begin
    result_mux = 32'b0;
    ready_mux  = 1'b0;
    exc_mux    = 5'b0;

    case(op_code)
        2'b00: begin
            result_mux = adder_result;
            ready_mux  = adder_ready;
            exc_mux    = adder_exc;
        end
        2'b01: begin
            result_mux = mult_result;
            ready_mux  = mult_ready;
            exc_mux    = mult_exc;
        end
        2'b10: begin
            result_mux = div_result;
            ready_mux  = div_ready;
            exc_mux    = div_exc;
        end
    endcase
end

always @(posedge clk or negedge rst_n) begin
if(!rst_n) begin
result_reg <= 32'b0;
ready_reg  <= 1'b0;
exc_reg    <= 5'b0;
end
else begin
result_reg <= result_mux;
ready_reg  <= ready_mux;
exc_reg    <= exc_mux;
end
end

assign result = result_reg;
assign ready = ready_reg;
assign exception = exc_reg;

endmodule