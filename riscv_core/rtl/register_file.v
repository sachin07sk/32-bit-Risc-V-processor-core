// ============================================
// Register File — 32 x 32-bit registers
// 2 async read ports, 1 sync write port
// x0 is hardwired to zero (RISC-V rule)
// ============================================
module register_file (
    input         clk,
    input         we,          // Write Enable (from WB stage)
    input  [4:0]  rs1,         // Source register 1 address (5-bit = 0..31)
    input  [4:0]  rs2,         // Source register 2 address
    input  [4:0]  rd,          // Destination register address
    input  [31:0] write_data,  // Data to write (from WB stage)
    output [31:0] read_data1,  // Value of rs1
    output [31:0] read_data2   // Value of rs2
);

    // 32 registers, each 32 bits wide
    reg [31:0] regs [0:31];

    // Initialize all registers to 0 at start (for simulation)
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'd0;
    end

    // Synchronous write — happens on rising clock edge
    // x0 can NEVER be written — RISC-V rule
    always @(posedge clk) begin
        if (we && rd != 5'd0)
            regs[rd] <= write_data;
    end

    // Asynchronous read — combinational, no clock needed
    // x0 always returns 0
    assign read_data1 = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    assign read_data2 = (rs2 == 5'd0) ? 32'd0 : regs[rs2];

endmodule
