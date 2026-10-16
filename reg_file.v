// RV32I Register File: 32 x 32-bit, 2 read ports, 1 write port
// BYPASS = 1 : a read of the register being written returns the new value
//              in the same cycle (use in the PIPELINED CPU)
// BYPASS = 0 : no bypass (use in the SINGLE-CYCLE CPU to avoid a
//              combinational loop)
module reg_file #(
    parameter BYPASS = 1
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        we,          // write enable (RegWrite)
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);
    reg [31:0] regs [0:31];
    integer i;

    // Synchronous write; x0 is never written
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;
        end else if (we && rd_addr != 5'd0) begin
            regs[rd_addr] <= rd_data;
        end
    end

    // Combinational read, with optional write-through bypass
    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 :
                      (BYPASS && we && rd_addr == rs1_addr) ? rd_data :
                      regs[rs1_addr];

    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 :
                      (BYPASS && we && rd_addr == rs2_addr) ? rd_data :
                      regs[rs2_addr];
endmodule