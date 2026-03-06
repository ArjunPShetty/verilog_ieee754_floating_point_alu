`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.03.2026 20:00:43
// Design Name: 
// Module Name: fp_alu_top_tb
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



module fp_alu_top_tb;

reg clk;
reg rst_n;
reg [31:0] op_a;
reg [31:0] op_b;
reg [1:0] op_code;
wire [31:0] result;
wire ready;
wire [4:0] exception;

localparam CLK_PERIOD = 10;

always #(CLK_PERIOD/2) clk = ~clk;

fp_alu_top dut (
    .clk(clk),
    .rst_n(rst_n),
    .op_a(op_a),
    .op_b(op_b),
    .op_code(op_code),
    .result(result),
    .ready(ready),
    .exception(exception)
);

integer test_num;

task test_operation;
input [31:0] a;
input [31:0] b;
input [1:0] op;
input [31:0] exp;
input [4:0] exp_exc;
begin
    @(negedge clk);
    op_a <= a;
    op_b <= b;
    op_code <= op;

    wait(ready == 1);
    @(posedge clk);

    if (result === exp)
        $display("Test %0d PASSED : %h %s %h = %h", test_num, a, op_name(op), b, result);
    else
        $display("Test %0d FAILED : %h %s %h = %h Expected %h", test_num, a, op_name(op), b, result, exp);

    if (exception !== exp_exc)
        $display("Exception mismatch Got %b Expected %b", exception, exp_exc);

    test_num = test_num + 1;
end
endtask

function [8*2:1] op_name;
input [1:0] op;
begin
    case(op)
        2'b00: op_name = "+";
        2'b01: op_name = "*";
        2'b10: op_name = "/";
        default: op_name = "?";
    endcase
end
endfunction

initial begin
    clk = 0;
    rst_n = 0;
    op_a = 0;
    op_b = 0;
    op_code = 0;
    test_num = 0;

    #20 rst_n = 1;

    test_operation(32'h3F800000,32'h3F800000,2'b00,32'h40000000,5'b00000);
    test_operation(32'h40000000,32'hBF800000,2'b00,32'h3F800000,5'b00000);
    test_operation(32'h40000000,32'h40000000,2'b01,32'h40800000,5'b00000);
    test_operation(32'h40800000,32'h40000000,2'b10,32'h40000000,5'b00000);
    test_operation(32'h3F800000,32'h00000000,2'b00,32'h3F800000,5'b00000);
    test_operation(32'h3F800000,32'h00000000,2'b01,32'h00000000,5'b00000);
    test_operation(32'h3F800000,32'h00000000,2'b10,32'h7F800000,5'b00010);
    test_operation(32'h7FC00000,32'h3F800000,2'b00,32'h7FC00000,5'b00001);
    test_operation(32'h7F800000,32'h3F800000,2'b01,32'h7F800000,5'b00000);
    test_operation(32'h33800000,32'h33800000,2'b00,32'h34000000,5'b00000);
    test_operation(32'h7F7FFFFF,32'h7F7FFFFF,2'b01,32'h7F800000,5'b00100);
    test_operation(32'hBF800000,32'hBF800000,2'b00,32'hC0000000,5'b00000);
    test_operation(32'hBF800000,32'hBF800000,2'b01,32'h3F800000,5'b00000);
    test_operation(32'hBF800000,32'h3F800000,2'b10,32'hBF800000,5'b00000);
    test_operation(32'h40000000,32'hC0000000,2'b00,32'h00000000,5'b00000);
    test_operation(32'h00400000,32'h3F800000,2'b01,32'h00400000,5'b00000);

    #100;
    $display("Tests completed %0d", test_num);
    $finish;
end

initial begin
    $dumpfile("fp_alu_tb.vcd");
    $dumpvars(0, fp_alu_top_tb);
end

always @(posedge clk) begin
    if (ready)
        $display("Time %0t Result %h Exception %b", $time, result, exception);
end

endmodule