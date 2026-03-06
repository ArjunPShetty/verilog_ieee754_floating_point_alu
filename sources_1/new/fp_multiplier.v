module fp_multiplier(
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
reg [23:0] man_a_norm;
reg [23:0] man_b_norm;
reg [47:0] man_product;
reg [7:0] result_exp;
reg [22:0] result_man;
reg result_sign;
reg invalid_op;
reg div_by_zero;
reg overflow;
reg underflow;
reg inexact;
reg [1:0] state;

localparam IDLE=2'b00,
           MULT=2'b01,
           NORMALIZE=2'b10;

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
        man_product <= 0;
        result_exp <= 0;
        result_man <= 0;
        result_sign <= 0;
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

            result_sign <= sign_a ^ sign_b;

            if(a_is_nan || b_is_nan)
            begin
                result <= 32'h7FC00000;
                exception <= 5'b00001;
                ready <= 1;
            end
            else if((a_is_inf && b_is_zero) || (a_is_zero && b_is_inf))
            begin
                result <= 32'h7FC00000;
                exception <= 5'b00001;
                ready <= 1;
            end
            else if(a_is_inf || b_is_inf)
            begin
                result <= {result_sign,8'hFF,23'b0};
                ready <= 1;
            end
            else if(a_is_zero || b_is_zero)
            begin
                result <= {result_sign,8'b0,23'b0};
                ready <= 1;
            end
            else
            begin
                man_a_norm <= {1'b1,man_a};
                man_b_norm <= {1'b1,man_b};

                state <= MULT;
            end
        end
        MULT:
        begin
            man_product <= man_a_norm * man_b_norm;
            result_exp <= exp_a + exp_b - 8'd127;
            state <= NORMALIZE;
        end
        NORMALIZE:
        begin
            if(man_product[47])
            begin
                man_product <= man_product >> 1;
                result_exp <= result_exp + 1;
            end
            result_man <= man_product[45:23];
            if(result_exp >= 8'hFF)
            begin
                overflow <= 1;
                result <= {result_sign,8'hFF,23'b0};
            end
            else if(result_exp <= 0)
            begin
                underflow <= 1;
                result <= {result_sign,8'b0,23'b0};
            end
            else
            begin
                result <= {result_sign,result_exp,result_man};
            end
            exception <= {invalid_op,div_by_zero,overflow,underflow,inexact};
            ready <= 1;
            state <= IDLE;
        end
        endcase
    end
end
endmodule