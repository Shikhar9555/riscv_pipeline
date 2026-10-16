`timescale 1ns/1ps
module tb_branch;
    reg         branch;
    reg  [2:0]  funct3;
    reg  [31:0] a, b;
    wire        taken;
    integer errors = 0;

    branch_unit dut (.branch(branch), .funct3(funct3),
                     .rs1_data(a), .rs2_data(b), .taken(taken));

    task check(input br, input [2:0] f3, input [31:0] x, input [31:0] y,
               input exp, input [8*24-1:0] name);
        begin
            branch = br; funct3 = f3; a = x; b = y; #10;
            if (taken !== exp) begin
                $display("FAIL: %0s  got %b expected %b", name, taken, exp);
                errors = errors + 1;
            end else
                $display("PASS: %0s  taken=%b", name, taken);
        end
    endtask

    initial begin
        $dumpfile("branch.vcd");
        $dumpvars(0, tb_branch);

        check(1, 3'b000, 32'd5, 32'd5, 1, "beq  5,5");
        check(1, 3'b000, 32'd5, 32'd3, 0, "beq  5,3");
        check(1, 3'b001, 32'd5, 32'd3, 1, "bne  5,3");
        check(1, 3'b001, 32'd5, 32'd5, 0, "bne  5,5");
        check(1, 3'b100, 32'hFFFFFFFF, 32'd1, 1, "blt  -1,1");
        check(1, 3'b100, 32'd1, 32'hFFFFFFFF, 0, "blt  1,-1");
        check(1, 3'b101, 32'd1, 32'hFFFFFFFF, 1, "bge  1,-1");
        check(1, 3'b101, 32'd5, 32'd5, 1, "bge  5,5");
        check(1, 3'b110, 32'hFFFFFFFF, 32'd1, 0, "bltu big,1");
        check(1, 3'b110, 32'd1, 32'hFFFFFFFF, 1, "bltu 1,big");
        check(1, 3'b111, 32'hFFFFFFFF, 32'd1, 1, "bgeu big,1");
        check(1, 3'b111, 32'd5, 32'd5, 1, "bgeu 5,5");
        check(0, 3'b000, 32'd5, 32'd5, 0, "not a branch");

        if (errors == 0) $display("\nALL TESTS PASSED");
        else             $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule