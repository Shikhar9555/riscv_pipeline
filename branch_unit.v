// RV32I Branch Unit: decides if a branch is taken
module branch_unit (
    input  wire        branch,      // from control unit
    input  wire [2:0]  funct3,
    input  wire [31:0] rs1_data,
    input  wire [31:0] rs2_data,
    output reg         taken
);
    wire eq  = (rs1_data == rs2_data);
    wire lt  = ($signed(rs1_data) < $signed(rs2_data));
    wire ltu = (rs1_data < rs2_data);

    always @(*) begin
        if (!branch)
            taken = 1'b0;
        else begin
            case (funct3)
                3'b000:  taken =  eq;    // BEQ
                3'b001:  taken = ~eq;    // BNE
                3'b100:  taken =  lt;    // BLT
                3'b101:  taken = ~lt;    // BGE
                3'b110:  taken =  ltu;   // BLTU
                3'b111:  taken = ~ltu;   // BGEU
                default: taken = 1'b0;
            endcase
        end
    end
endmodule