// RV32I Single-Cycle CPU
module riscv_single_cycle #(
    parameter INIT_FILE = "program.hex"
)(
    input wire clk,
    input wire rst
);
    // ---------------- Fetch ----------------
    reg  [31:0] pc;
    wire [31:0] instr;

    imem #(.DEPTH(1024), .INIT_FILE(INIT_FILE)) im (
        .addr(pc), .instr(instr)
    );

    // ---------------- Decode fields ----------------
    wire [6:0] opcode   = instr[6:0];
    wire [4:0] rd       = instr[11:7];
    wire [2:0] funct3   = instr[14:12];
    wire [4:0] rs1      = instr[19:15];
    wire [4:0] rs2      = instr[24:20];
    wire       funct7_5 = instr[30];

    // ---------------- Control ----------------
    wire       reg_write, mem_read, mem_write, alu_src, branch, jump, jalr;
    wire [1:0] alu_a_sel, result_src, alu_op;
    wire [3:0] alu_ctrl;

    control_unit cu (
        .opcode(opcode),
        .reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
        .alu_src(alu_src), .alu_a_sel(alu_a_sel), .result_src(result_src),
        .branch(branch), .jump(jump), .jalr(jalr), .alu_op(alu_op)
    );

    alu_control ac (
        .alu_op(alu_op), .funct3(funct3), .funct7_5(funct7_5),
        .alu_ctrl(alu_ctrl)
    );

    // ---------------- Register file & immediate ----------------
    wire [31:0] rs1_data, rs2_data, result, imm;

    reg_file #(.BYPASS(0)) rf (
        .clk(clk), .rst(rst), .we(reg_write),
        .rs1_addr(rs1), .rs2_addr(rs2), .rd_addr(rd), .rd_data(result),
        .rs1_data(rs1_data), .rs2_data(rs2_data)
    );

    imm_gen ig (.instr(instr), .imm(imm));

    // ---------------- Execute ----------------
    wire [31:0] alu_a = (alu_a_sel == 2'b01) ? pc    :
                        (alu_a_sel == 2'b10) ? 32'd0 : rs1_data;
    wire [31:0] alu_b = alu_src ? imm : rs2_data;
    wire [31:0] alu_result;

    alu alu_i (
        .a(alu_a), .b(alu_b), .alu_ctrl(alu_ctrl),
        .result(alu_result), .zero()
    );

    wire taken;
    branch_unit bu (
        .branch(branch), .funct3(funct3),
        .rs1_data(rs1_data), .rs2_data(rs2_data), .taken(taken)
    );

    // ---------------- Memory ----------------
    wire [31:0] mem_rdata;

    dmem #(.DEPTH(1024)) dm (
        .clk(clk), .mem_write(mem_write), .funct3(funct3),
        .addr(alu_result), .wdata(rs2_data), .rdata(mem_rdata)
    );

    // ---------------- Write back ----------------
    wire [31:0] pc_plus4  = pc + 32'd4;
    wire [31:0] pc_target = pc + imm;

    assign result = (result_src == 2'b01) ? mem_rdata :
                    (result_src == 2'b10) ? pc_plus4  : alu_result;

    // ---------------- Next PC ----------------
    wire [31:0] next_pc = jalr            ? (alu_result & ~32'd1) :
                          (jump || taken) ? pc_target             : pc_plus4;

    always @(posedge clk) begin
        if (rst) pc <= 32'd0;
        else     pc <= next_pc;
    end
endmodule