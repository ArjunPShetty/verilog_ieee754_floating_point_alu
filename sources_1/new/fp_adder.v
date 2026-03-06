module fp_adder(
    input clk,
    input rst_n,
    input [31:0] op_a,
    input [31:0] op_b,
    output reg [31:0] result,
    output reg ready,
    output reg [4:0] exception
);

wire sign_a = op_a[31];
wire sign_b = op_b[31];
wire [7:0] exp_a = op_a[30:23];
wire [7:0] exp_b = op_b[30:23];
wire [22:0] man_a = op_a[22:0];
wire [22:0] man_b = op_b[22:0];
wire a_is_zero = (exp_a==0 && man_a==0);
wire b_is_zero = (exp_b==0 && man_b==0);
wire a_is_inf  = (exp_a==8'hFF && man_a==0);
wire b_is_inf  = (exp_b==8'hFF && man_b==0);
wire a_is_nan  = (exp_a==8'hFF && man_a!=0);
wire b_is_nan  = (exp_b==8'hFF && man_b!=0);

reg [24:0] man_a_norm;
reg [24:0] man_b_norm;
reg [7:0] exp_large;
reg [7:0] exp_diff;
reg [24:0] man_large;
reg [24:0] man_small;
reg [24:0] man_sum;
reg [24:0] man_diff;
reg result_sign;
reg [7:0] result_exp;
reg [23:0] result_man;
reg invalid_op;
reg div_by_zero;
reg overflow;
reg underflow;
reg inexact;
reg [1:0] state;

localparam IDLE=2'b00,
           ALIGN=2'b01,
           ADD=2'b10,
           NORMALIZE=2'b11;
always @(posedge clk or negedge rst_n)
begin
if(!rst_n)
begin
    state <= IDLE;
    ready <= 0;
    result <= 0;
    exception <= 0;

    invalid_op <= 0;
    div_by_zero <= 0;
    overflow <= 0;
    underflow <= 0;
    inexact <= 0;

    man_a_norm <= 0;
    man_b_norm <= 0;
    exp_large <= 0;
    exp_diff <= 0;
    man_large <= 0;
    man_small <= 0;
    man_sum <= 0;
    man_diff <= 0;
    result_sign <= 0;
    result_exp <= 0;
    result_man <= 0;
end
    else
    begin
        case(state)
        IDLE:
        begin
            ready <= 0;
            invalid_op <= 0;
            div_by_zero <= 0;
            overflow <= 0;
            underflow <= 0;
            inexact <= 0;

            if(a_is_nan || b_is_nan)
            begin
                result <= 32'h7FC00000;
                exception <= 5'b00001;
                ready <= 1;
            end
            else if(a_is_inf && b_is_inf && sign_a!=sign_b)
            begin
                result <= 32'h7FC00000;
                exception <= 5'b00001;
                ready <= 1;
            end
            else if(a_is_inf || b_is_inf)
            begin
                result <= a_is_inf ? {sign_a,8'hFF,23'b0}:{sign_b,8'hFF,23'b0};
                ready <= 1;
            end
            else
            begin
                man_a_norm <= {1'b1,man_a,1'b0};
                man_b_norm <= {1'b1,man_b,1'b0};
                state <= ALIGN;
            end
        end

        ALIGN:
        begin
            if(exp_a > exp_b)
            begin
                exp_large <= exp_a;
                exp_diff <= exp_a-exp_b;
                man_large <= man_a_norm;
                man_small <= man_b_norm >> (exp_a-exp_b);
                result_sign <= sign_a;
            end
            else
            begin
                exp_large <= exp_b;
                exp_diff <= exp_b-exp_a;
                man_large <= man_b_norm;
                man_small <= man_a_norm >> (exp_b-exp_a);
                result_sign <= sign_b;
            end

            state <= ADD;
        end
        ADD:
        begin
            if(sign_a == sign_b)
            begin
                man_sum <= man_large + man_small;
            end
            else
            begin
                if(man_large >= man_small)
                    man_diff <= man_large - man_small;
                else
                    man_diff <= man_small - man_large;
            end
            state <= NORMALIZE;
        end
        NORMALIZE:
        begin
            if(sign_a == sign_b)
            begin
                if(man_sum[24])
                begin
                    result_exp <= exp_large + 1;
                    result_man <= man_sum[23:0];
                end
                else
                begin
                    result_exp <= exp_large;
                    result_man <= man_sum[22:0];
                end
            end
            else
            begin
                result_exp <= exp_large;
                result_man <= man_diff[22:0];
            end
            if(result_exp >= 8'hFF)
            begin
                overflow <= 1;
                result <= {result_sign,8'hFF,23'b0};
            end
            else
            begin
                result <= {result_sign,result_exp,result_man[22:0]};
            end
            exception <= {invalid_op,div_by_zero,overflow,underflow,inexact};
            ready <= 1;
            state <= IDLE;
        end
        endcase
    end
end
endmodule