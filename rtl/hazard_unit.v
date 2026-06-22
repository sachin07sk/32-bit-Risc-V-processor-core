// ============================================
// Hazard Detection Unit
// Detects 2 types of hazards:
//   1. Load-Use Hazard  → inserts 1 stall bubble
//   2. Control Hazard   → flushes 2 instructions on branch taken
// ============================================
module hazard_unit (
    // --- Inputs from pipeline registers ---

    // From IF/ID register (currently decoding instruction)
    input [4:0] if_id_rs1,      // Source register 1 of current instruction
    input [4:0] if_id_rs2,      // Source register 2 of current instruction

    // From ID/EX register (instruction in execute stage)
    input       id_ex_mem_read, // 1 = instruction in EX is a LOAD (LW)
    input [4:0] id_ex_rd,       // Destination register of instruction in EX

    // From EX/MEM register (instruction in memory stage)
    input       branch_taken,   // 1 = branch condition is TRUE, must flush

    // --- Outputs to control pipeline ---
    output reg  pc_stall,       // 1 = freeze the Program Counter
    output reg  if_id_stall,    // 1 = freeze the IF/ID pipeline register
    output reg  id_ex_flush,    // 1 = flush ID/EX register (insert NOP bubble)
    output reg  if_id_flush     // 1 = flush IF/ID register (branch penalty)
);

    always @(*) begin
        // Default: no hazard — everything runs normally
        pc_stall    = 0;
        if_id_stall = 0;
        id_ex_flush = 0;
        if_id_flush = 0;

        // =========================================
        // HAZARD TYPE 1: Load-Use Hazard
        // =========================================
        // Condition:
        //   - Instruction in EX stage is a LOAD (mem_read=1)
        //   - AND it writes to a register (id_ex_rd)
        //   - AND the NEXT instruction (in ID) reads that same register
        //
        // Example:
        //   LW  x1, 0(x2)   ← in EX stage,  id_ex_rd = x1, mem_read = 1
        //   ADD x3, x1, x4  ← in ID stage,  if_id_rs1 = x1
        //                                    HAZARD! x1 not ready yet
        // =========================================

        if (id_ex_mem_read &&
            (id_ex_rd == if_id_rs1 || id_ex_rd == if_id_rs2) &&
            id_ex_rd != 5'd0)         // x0 never causes hazard (always 0)
        begin
            pc_stall    = 1;  // Freeze PC → fetch same instruction again
            if_id_stall = 1;  // Freeze IF/ID → hold current instruction
            id_ex_flush = 1;  // Flush ID/EX → insert NOP bubble into EX
        end

        // =========================================
        // HAZARD TYPE 2: Control Hazard (Branch Taken)
        // =========================================
        // When a branch (BEQ/BNE) is TAKEN, the processor has already
        // fetched 2 wrong instructions behind it.
        // We must flush them — turn them into NOPs.
        //
        // Example:
        //   BEQ x1, x2, LABEL   ← branch decided in EX stage
        //   ADD x3, x4, x5      ← fetched but WRONG — must flush (IF stage)
        //   SUB x6, x7, x8      ← fetched but WRONG — must flush (ID stage)
        //
        // Note: if load-use stall is also active, stall takes priority.
        // =========================================

        if (branch_taken && !pc_stall) begin
            if_id_flush = 1;  // Flush instruction currently in IF/ID
            id_ex_flush = 1;  // Flush instruction currently in ID/EX
            // PC is already updated to branch target by EX stage
            // so no pc_stall needed here
        end
    end

endmodule
