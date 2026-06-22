module mem_stage (
    input         clk,
    input         reset,
    input  [31:0] ex_mem_pc_branch,
    input         ex_mem_branch,
    input         ex_mem_zero,
    input  [31:0] ex_mem_alu_result,
    input  [31:0] ex_mem_write_data,
    input  [4:0]  ex_mem_rd,
    input         ex_mem_mem_read,
    input         ex_mem_mem_write,
    input         ex_mem_reg_write,
    input         ex_mem_mem_to_reg,
    input  [31:0] mem_read_data,
    output        mem_we,
    output [31:0] mem_addr,
    output [31:0] mem_write_data,
    output        branch_taken,
    output [31:0] branch_target,
    output reg [31:0] mem_wb_read_data,
    output reg [31:0] mem_wb_alu_result,
    output reg [4:0]  mem_wb_rd,
    output reg        mem_wb_reg_write,
    output reg        mem_wb_mem_to_reg
);

    assign mem_we         = ex_mem_mem_write;
    assign mem_addr       = ex_mem_alu_result;
    assign mem_write_data = ex_mem_write_data;
    assign branch_taken   = ex_mem_branch & ex_mem_zero;
    assign branch_target  = ex_mem_pc_branch;

    always @(posedge clk) begin
        if (reset) begin
            mem_wb_read_data  <= 32'd0;
            mem_wb_alu_result <= 32'd0;
            mem_wb_rd         <= 5'd0;
            mem_wb_reg_write  <= 0;
            mem_wb_mem_to_reg <= 0;
        end
        else begin
            mem_wb_read_data  <= mem_read_data;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_rd         <= ex_mem_rd;
            mem_wb_reg_write  <= ex_mem_reg_write;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
        end
    end

endmodule
