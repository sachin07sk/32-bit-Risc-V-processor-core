// ============================================
// Program Counter
// Increments by 4 each cycle (word-addressed)
// Loads branch/jump target when pc_sel = 1
// ============================================
module pc (
    input         clk,
    input         reset,      // Synchronous reset → PC goes to 0x00000000
    input         stall,      // Freeze PC (used during hazard)
    input         pc_sel,     // 0 = PC+4 (normal), 1 = branch/jump target
    input  [31:0] pc_target,  // Branch/jump destination address
    output reg [31:0] pc_out  // Current PC value
);

    always @(posedge clk) begin
        if (reset)
            pc_out <= 32'h00000000;   // Start execution from address 0
        else if (!stall) begin        // Only update if not stalled
            if (pc_sel)
                pc_out <= pc_target;  // Take branch/jump
            else
                pc_out <= pc_out + 4; // Normal: next instruction
        end
        // If stall=1 and no reset: PC holds its value (freeze)
    end

endmodule
