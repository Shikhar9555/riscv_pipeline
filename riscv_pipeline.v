// RV32I 5-Stage Pipelined CPU  -  FINAL: forwarding + hazard detection
// Stage prefixes:  d_ = ID stage, e_ = EX, m_ = MEM, w_ = WB
module riscv_pipeline #(
    parameter INIT_FILE = "program.hex"
)(
    input wire clk,
    input wire rst
);
    localparam NOP = 32'h00000013;

    // ================= Hazard control (from hazard_unit) =================
    wire stall_f;   // hold PC
    wire stall_d;   // hold IF/ID
    wire flush_d;   // clear IF/ID  (turn into NOP)
    wire flush_e;   // clear ID/EX  (turn into NOP / bubble)

    // ================= Pipeline register declarations =================
    // IF/ID
    reg  [31:0] d_pc, d_instr;
    // ID/EX
    reg         e_reg_write, e_mem_read, e_mem_write, e_alu_src;
    reg         e_branch, e_jump, e_jalr, e_funct7_5;
    reg  [1:0]  e_alu_a_sel, e_result_src, e_alu_op;
    reg  [2:0]  e_funct3;
    reg  [4:0]  e_rs1, e_rs2, e_rd;
    reg  [31:0] e_pc, e_rs1_data, e_rs2_data, e_imm, e_instr;
    // EX/MEM
    reg         m_reg_write, m_mem_write;
    reg  [1:0]  m_result_src;
    reg  [2:0]  m_funct3;
    reg  [4:0]  m_rd;
    reg  [31:0] m_alu_result, m_write_data, m_pc_plus4, m_instr;
    // MEM/WB
    reg         w_reg_write;
    reg  [1:0]  w_result_src;
    reg  [4:0]  w_rd;
    reg  [31:0] w_alu_result, w_mem_rdata, w_pc_plus4, w_instr;

    // Signals used before the stage that creates them
    wire        pc_sel_e;        // 1 = redirect PC (taken branch / jump)
    wire [31:0] pc_redirect_e;   // redirect target
    wire [31:0] w_result;        // value written back to the register file

    // ======================= IF: Instruction Fetch =======================
    reg  [31:0] pc;
    wire [31:0] instr_f;
    wire [31:0] pc_plus4_f = pc + 32'd4;
    wire [31:0] next_pc    = pc_sel_e ? pc_redirect_e : pc_plus4_f;

    imem #(.DEPTH(1024), .INIT_FILE(INIT_FILE)) im (
        .addr(pc), .instr(instr_f)
    );

    always @(posedge clk) begin
        if (rst)           pc <= 32'd0;
        else if (!stall_f) pc <= next_pc;
    end

    // ---------------------------- IF/ID ----------------------------
    always @(posedge clk) begin
        if (rst || flush_d) begin
            d_pc    <= 32'd0;
            d_instr <= NOP;
        end else if (!stall_d) begin
            d_pc    <= pc;
            d_instr <= instr_f;
        end
    end

    // ======================= ID: Instruction Decode ======================
    wire [6:0] d_opcode   = d_instr[6:0];
    wire [4:0] d_rd       = d_instr[11:7];
    wire [2:0] d_funct3   = d_instr[14:12];
    wire [4:0] d_rs1      = d_instr[19:15];
    wire [4:0] d_rs2      = d_instr[24:20];
    wire       d_funct7_5 = d_instr[30];

    wire       d_reg_write, d_mem_read, d_mem_write, d_alu_src;
    wire       d_branch, d_jump, d_jalr;
    wire [1:0] d_alu_a_sel, d_result_src, d_alu_op;

    control_unit cu (
        .opcode(d_opcode),
        .reg_write(d_reg_write), .mem_read(d_mem_read), .mem_write(d_mem_write),
        .alu_src(d_alu_src), .alu_a_sel(d_alu_a_sel), .result_src(d_result_src),
        .branch(d_branch), .jump(d_jump), .jalr(d_jalr), .alu_op(d_alu_op)
    );

    wire [31:0] d_imm;
    imm_gen ig (.instr(d_instr), .imm(d_imm));

    wire [31:0] d_rs1_data, d_rs2_data;
    reg_file #(.BYPASS(1)) rf (
        .clk(clk), .rst(rst),
        .we(w_reg_write), .rd_addr(w_rd), .rd_data(w_result),   // write port from WB
        .rs1_addr(d_rs1), .rs2_addr(d_rs2),
        .rs1_data(d_rs1_data), .rs2_data(d_rs2_data)
    );

    // ---------------------------- ID/EX ----------------------------
    always @(posedge clk) begin
        if (rst || flush_e) begin
            e_reg_write <= 1'b0;  e_mem_read  <= 1'b0;  e_mem_write <= 1'b0;
            e_alu_src   <= 1'b0;  e_branch    <= 1'b0;  e_jump      <= 1'b0;
            e_jalr      <= 1'b0;  e_funct7_5  <= 1'b0;
            e_alu_a_sel <= 2'b00; e_result_src <= 2'b00; e_alu_op   <= 2'b00;
            e_funct3    <= 3'b000;
            e_rs1 <= 5'd0; e_rs2 <= 5'd0; e_rd <= 5'd0;
            e_pc  <= 32'd0; e_rs1_data <= 32'd0; e_rs2_data <= 32'd0;
            e_imm <= 32'd0; e_instr <= NOP;
        end else begin
            e_reg_write <= d_reg_write;  e_mem_read  <= d_mem_read;
            e_mem_write <= d_mem_write;  e_alu_src   <= d_alu_src;
            e_branch    <= d_branch;     e_jump      <= d_jump;
            e_jalr      <= d_jalr;       e_funct7_5  <= d_funct7_5;
            e_alu_a_sel <= d_alu_a_sel;  e_result_src <= d_result_src;
            e_alu_op    <= d_alu_op;     e_funct3    <= d_funct3;
            e_rs1 <= d_rs1; e_rs2 <= d_rs2; e_rd <= d_rd;
            e_pc  <= d_pc;  e_rs1_data <= d_rs1_data; e_rs2_data <= d_rs2_data;
            e_imm <= d_imm; e_instr <= d_instr;
        end
    end

    // ========================== EX: Execute ==========================
    wire [3:0] e_alu_ctrl;
    alu_control ac (
        .alu_op(e_alu_op), .funct3(e_funct3), .funct7_5(e_funct7_5),
        .alu_ctrl(e_alu_ctrl)
    );

    // ---------------- Forwarding ----------------
    wire [1:0] forward_a, forward_b;

    forwarding_unit fu (
        .e_rs1(e_rs1), .e_rs2(e_rs2),
        .m_rd(m_rd), .m_reg_write(m_reg_write),
        .w_rd(w_rd), .w_reg_write(w_reg_write),
        .forward_a(forward_a), .forward_b(forward_b)
    );

    // Value available in EX/MEM: PC+4 for jal/jalr, otherwise the ALU result
    wire [31:0] m_fwd_value = (m_result_src == 2'b10) ? m_pc_plus4 : m_alu_result;

    wire [31:0] e_src_a = (forward_a == 2'b10) ? m_fwd_value :
                          (forward_a == 2'b01) ? w_result    : e_rs1_data;
    wire [31:0] e_src_b = (forward_b == 2'b10) ? m_fwd_value :
                          (forward_b == 2'b01) ? w_result    : e_rs2_data;

    // ---------------- ALU ----------------
    wire [31:0] e_alu_a = (e_alu_a_sel == 2'b01) ? e_pc  :
                          (e_alu_a_sel == 2'b10) ? 32'd0 : e_src_a;
    wire [31:0] e_alu_b = e_alu_src ? e_imm : e_src_b;
    wire [31:0] e_alu_result;

    alu alu_i (
        .a(e_alu_a), .b(e_alu_b), .alu_ctrl(e_alu_ctrl),
        .result(e_alu_result), .zero()
    );

    // ---------------- Branch decision ----------------
    wire e_taken;
    branch_unit bu (
        .branch(e_branch), .funct3(e_funct3),
        .rs1_data(e_src_a), .rs2_data(e_src_b), .taken(e_taken)
    );

    wire [31:0] e_pc_plus4 = e_pc + 32'd4;
    assign pc_sel_e      = e_jump | e_jalr | e_taken;
    assign pc_redirect_e = e_jalr ? (e_alu_result & ~32'd1) : (e_pc + e_imm);

    // ---------------------------- EX/MEM ----------------------------
    always @(posedge clk) begin
        if (rst) begin
            m_reg_write <= 1'b0; m_mem_write <= 1'b0; m_result_src <= 2'b00;
            m_funct3 <= 3'b000;  m_rd <= 5'd0;
            m_alu_result <= 32'd0; m_write_data <= 32'd0;
            m_pc_plus4 <= 32'd0;   m_instr <= NOP;
        end else begin
            m_reg_write  <= e_reg_write;  m_mem_write  <= e_mem_write;
            m_result_src <= e_result_src; m_funct3     <= e_funct3;
            m_rd         <= e_rd;         m_alu_result <= e_alu_result;
            m_write_data <= e_src_b;      m_pc_plus4   <= e_pc_plus4;
            m_instr      <= e_instr;
        end
    end

    // ========================== MEM: Memory ==========================
    wire [31:0] m_rdata;
    dmem #(.DEPTH(1024)) dm (
        .clk(clk), .mem_write(m_mem_write), .funct3(m_funct3),
        .addr(m_alu_result), .wdata(m_write_data), .rdata(m_rdata)
    );

    // ---------------------------- MEM/WB ----------------------------
    always @(posedge clk) begin
        if (rst) begin
            w_reg_write <= 1'b0; w_result_src <= 2'b00; w_rd <= 5'd0;
            w_alu_result <= 32'd0; w_mem_rdata <= 32'd0;
            w_pc_plus4 <= 32'd0;   w_instr <= NOP;
        end else begin
            w_reg_write  <= m_reg_write;  w_result_src <= m_result_src;
            w_rd         <= m_rd;         w_alu_result <= m_alu_result;
            w_mem_rdata  <= m_rdata;      w_pc_plus4   <= m_pc_plus4;
            w_instr      <= m_instr;
        end
    end

    // ========================= WB: Write Back =========================
    assign w_result = (w_result_src == 2'b01) ? w_mem_rdata :
                      (w_result_src == 2'b10) ? w_pc_plus4  : w_alu_result;

    // ======================= Hazard detection =======================
    hazard_unit hu (
        .d_rs1(d_rs1), .d_rs2(d_rs2),
        .e_rd(e_rd), .e_mem_read(e_mem_read),
        .pc_sel_e(pc_sel_e),
        .stall_f(stall_f), .stall_d(stall_d),
        .flush_d(flush_d), .flush_e(flush_e)
    );
endmodule