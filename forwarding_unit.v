// Forwarding Unit
// forward = 00 : use value from register file (ID/EX)
//           10 : forward from EX/MEM  (instruction 1 ahead)
//           01 : forward from MEM/WB  (instruction 2 ahead)
module forwarding_unit (
    input  wire [4:0] e_rs1,
    input  wire [4:0] e_rs2,
    input  wire [4:0] m_rd,
    input  wire       m_reg_write,
    input  wire [4:0] w_rd,
    input  wire       w_reg_write,
    output reg  [1:0] forward_a,
    output reg  [1:0] forward_b
);
    always @(*) begin
        // ---- Operand A (rs1) ----
        if (m_reg_write && m_rd != 5'd0 && m_rd == e_rs1)
            forward_a = 2'b10;
        else if (w_reg_write && w_rd != 5'd0 && w_rd == e_rs1)
            forward_a = 2'b01;
        else
            forward_a = 2'b00;

        // ---- Operand B (rs2) ----
        if (m_reg_write && m_rd != 5'd0 && m_rd == e_rs2)
            forward_b = 2'b10;
        else if (w_reg_write && w_rd != 5'd0 && w_rd == e_rs2)
            forward_b = 2'b01;
        else
            forward_b = 2'b00;
    end
endmodule