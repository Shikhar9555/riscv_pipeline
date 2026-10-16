// Data Memory: byte/halfword/word loads and stores, little-endian
module dmem #(
    parameter DEPTH = 1024                   // number of 32-bit words
)(
    input  wire        clk,
    input  wire        mem_write,
    input  wire [2:0]  funct3,               // access size and sign
    input  wire [31:0] addr,                 // byte address
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);
    localparam AW = $clog2(DEPTH);
    reg [31:0] mem [0:DEPTH-1];
    wire [AW-1:0] widx = addr[AW+1:2];
    wire [31:0]   word = mem[widx];
    integer i;

    initial
        for (i = 0; i < DEPTH; i = i + 1) mem[i] = 32'd0;

    // ---------- Store (synchronous) ----------
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3[1:0])
                2'b00: begin                             // SB
                    case (addr[1:0])
                        2'b00: mem[widx][7:0]   <= wdata[7:0];
                        2'b01: mem[widx][15:8]  <= wdata[7:0];
                        2'b10: mem[widx][23:16] <= wdata[7:0];
                        2'b11: mem[widx][31:24] <= wdata[7:0];
                    endcase
                end
                2'b01: begin                             // SH
                    if (addr[1]) mem[widx][31:16] <= wdata[15:0];
                    else         mem[widx][15:0]  <= wdata[15:0];
                end
                default: mem[widx] <= wdata;             // SW
            endcase
        end
    end

    // ---------- Load (combinational) ----------
    reg [7:0]  byte_sel;
    reg [15:0] half_sel;

    always @(*) begin
        case (addr[1:0])
            2'b00: byte_sel = word[7:0];
            2'b01: byte_sel = word[15:8];
            2'b10: byte_sel = word[23:16];
            2'b11: byte_sel = word[31:24];
        endcase
        half_sel = addr[1] ? word[31:16] : word[15:0];

        case (funct3)
            3'b000:  rdata = {{24{byte_sel[7]}},  byte_sel};   // LB  (sign-extend)
            3'b001:  rdata = {{16{half_sel[15]}}, half_sel};   // LH  (sign-extend)
            3'b010:  rdata = word;                             // LW
            3'b100:  rdata = {24'd0, byte_sel};                // LBU (zero-extend)
            3'b101:  rdata = {16'd0, half_sel};                // LHU (zero-extend)
            default: rdata = word;
        endcase
    end
endmodule