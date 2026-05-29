// ============================================
// IF Stage — Instruction Fetch
// + IF/ID Pipeline Register
// ============================================
module if_stage (
    input         clk,
    input         reset,
    input         stall,        // From hazard unit — freeze this register
    input         flush,        // From hazard unit — clear on branch
    input  [31:0] pc_current,   // Current PC value
    input  [31:0] instruction,  // From instruction memory

    // IF/ID pipeline register outputs (go to ID stage)
    output reg [31:0] if_id_pc,          // PC value passed forward
    output reg [31:0] if_id_instruction  // Instruction passed forward
);

    always @(posedge clk) begin
        if (reset || flush) begin
            // Flush: clear register → becomes NOP (all zeros)
            if_id_pc          <= 32'd0;
            if_id_instruction <= 32'd0;  // 0x00000000 = NOP in RISC-V
        end
        else if (!stall) begin
            // Normal operation: latch current values
            if_id_pc          <= pc_current;
            if_id_instruction <= instruction;
        end
        // If stall=1 and no flush/reset: register holds its value
    end

endmodule
