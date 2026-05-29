// ============================================
// WB Stage — Write Back
// Selects what goes back to the register file
// mem_to_reg=1 → write memory data (LW result)
// mem_to_reg=0 → write ALU result
// ============================================
module wb_stage (
    // From MEM/WB register
    input  [31:0] mem_wb_read_data,
    input  [31:0] mem_wb_alu_result,
    input  [4:0]  mem_wb_rd,
    input         mem_wb_reg_write,
    input         mem_wb_mem_to_reg,

    // To register file
    output [4:0]  wb_rd,
    output        wb_reg_write,
    output [31:0] wb_write_data  // Also used by forwarding unit
);

    assign wb_rd         = mem_wb_rd;
    assign wb_reg_write  = mem_wb_reg_write;

    // MUX: choose between memory data or ALU result
    assign wb_write_data = mem_wb_mem_to_reg ?
                           mem_wb_read_data :   // LW → write loaded value
                           mem_wb_alu_result;   // ALU → write computed value

endmodule
