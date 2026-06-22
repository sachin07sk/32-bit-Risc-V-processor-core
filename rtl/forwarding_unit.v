// ============================================
// Forwarding Unit
// Detects RAW (Read After Write) data hazards
// and selects the correct bypass path for the
// ALU operands in the EX stage.
//
// Outputs:
//   fwd_a → selects operand A source for ALU
//   fwd_b → selects operand B source for ALU
//
// Encoding (must match ex_stage.v MUX):
//   2'b00 = register file (no forwarding)
//   2'b10 = EX/MEM bypass (1 stage ahead)
//   2'b01 = MEM/WB bypass (2 stages ahead)
// ============================================
module forwarding_unit (
    // What the EX stage currently needs
    input [4:0] id_ex_rs1,         // Source register 1 of instruction in EX
    input [4:0] id_ex_rs2,         // Source register 2 of instruction in EX

    // What the MEM stage will write (1 stage ahead of EX)
    input       ex_mem_reg_write,  // 1 = MEM stage instruction writes a register
    input [4:0] ex_mem_rd,         // Which register MEM stage writes to

    // What the WB stage will write (2 stages ahead of EX)
    input       mem_wb_reg_write,  // 1 = WB stage instruction writes a register
    input [4:0] mem_wb_rd,         // Which register WB stage writes to

    // Forwarding select signals → go to MUX in ex_stage.v
    output reg [1:0] fwd_a,        // Select for operand A (rs1)
    output reg [1:0] fwd_b         // Select for operand B (rs2)
);

    always @(*) begin

        // ── OPERAND A (rs1) ─────────────────────────────────
        // Default: no forwarding — use register file value
        fwd_a = 2'b00;

        // Priority 1: EX/MEM bypass — most recent value wins
        // Condition: MEM stage is writing a register AND
        //            it is writing to the same register EX needs AND
        //            it is not x0 (x0 never needs forwarding)
        if (ex_mem_reg_write &&
            ex_mem_rd != 5'd0 &&
            ex_mem_rd == id_ex_rs1)
        begin
            fwd_a = 2'b10;  // Take from EX/MEM register
        end

        // Priority 2: MEM/WB bypass — only if EX/MEM didn't match
        // Condition: WB stage is writing a register AND
        //            it is writing to the same register EX needs AND
        //            it is not x0
        else if (mem_wb_reg_write &&
                 mem_wb_rd != 5'd0 &&
                 mem_wb_rd == id_ex_rs1)
        begin
            fwd_a = 2'b01;  // Take from MEM/WB register
        end

        // If neither matches: fwd_a stays 2'b00 (register file)

        // ── OPERAND B (rs2) ─────────────────────────────────
        // Exact same logic — just checks rs2 instead of rs1
        fwd_b = 2'b00;

        if (ex_mem_reg_write &&
            ex_mem_rd != 5'd0 &&
            ex_mem_rd == id_ex_rs2)
        begin
            fwd_b = 2'b10;  // EX/MEM bypass
        end

        else if (mem_wb_reg_write &&
                 mem_wb_rd != 5'd0 &&
                 mem_wb_rd == id_ex_rs2)
        begin
            fwd_b = 2'b01;  // MEM/WB bypass
        end

    end

endmodule
