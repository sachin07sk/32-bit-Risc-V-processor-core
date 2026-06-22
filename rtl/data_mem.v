module data_mem (
    input         clk,
    input         we,
    input  [31:0] addr,
    input  [31:0] write_data,
    output [31:0] read_data
);
    reg [31:0] mem [0:255];

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'd0;
    end

    always @(posedge clk) begin
        if (we)
            mem[addr[9:2]] <= write_data;
    end

    assign read_data = mem[addr[9:2]];
endmodule
