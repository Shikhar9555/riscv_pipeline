`timescale 1ns/1ps
module tb_alu;
    reg  [31:0] a, b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero;
    integer errors = 0;

    alu dut (.a(a), .b(b), .alu_ctrl(alu_ctrl), .result(result), .zero(zero));

    task check(input [3:0] op, input [31:0] x, input [31:0] y, input [31:0] expected);
        begin
            a = x; b = y; alu_ctrl = op;
            #10;
            if (result !== expected) begin
                $display("FAIL: op=%b a=%h b=%h -> got %h, expected %h", op, x, y, result, expected);
                errors = errors + 1;
            end else
                $display("PASS: op=%b a=%h b=%h -> %h", op, x, y, result);
        end
    endtask

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, tb_alu);

        check(4'b0000, 32'd5,        32'd3,  32'd8);         // ADD
        check(4'b0001, 32'd5,        32'd3,  32'd2);         // SUB
        check(4'b0010, 32'hF0F0,     32'hFF00, 32'hF000);    // AND
        check(4'b0011, 32'hF0F0,     32'h0F0F, 32'hFFFF);    // OR
        check(4'b0100, 32'hFFFF,     32'h0F0F, 32'hF0F0);    // XOR
        check(4'b0101, 32'd1,        32'd4,  32'd16);        // SLL
        check(4'b0110, 32'h80000000, 32'd4,  32'h08000000);  // SRL
        check(4'b0111, 32'h80000000, 32'd4,  32'hF8000000);  // SRA
        check(4'b1000, 32'hFFFFFFFF, 32'd1,  32'd1);         // SLT  (-1 < 1)
        check(4'b1001, 32'hFFFFFFFF, 32'd1,  32'd0);         // SLTU (big > 1)

        if (errors == 0) $display("\nALL TESTS PASSED");
        else             $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule