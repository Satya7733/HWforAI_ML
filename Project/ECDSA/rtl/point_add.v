// stub: simple affine add P + Q mod p, with p hardcoded
module point_add(
    input  logic         clk,
    input  logic         rst_n,
    input  logic [255:0] x1, y1,
    input  logic [255:0] x2, y2,
    output logic [255:0] x3, y3,
    output logic         valid
);
    // For now, just pass through x3=x1^x2, y3=y1^y2
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x3    <= '0;
            y3    <= '0;
            valid <= 0;
        end else begin
            x3    <= x1 ^ x2;
            y3    <= y1 ^ y2;
            valid <= 1;
        end
    end
endmodule
