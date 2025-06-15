
// File: src/mod_mul.v
// Computes R = (A * B) mod p, where
//   p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
//
// Algorithm (sequential, 256 cycles):
//   - accum ← 0
//   - base ← A
//   - multiplier ← B
//   - For i = 0 to 255:
//       if (multiplier[0] == 1) accum ← (accum + base) mod p
//       base ← (base + base) mod p
//       multiplier ← multiplier >> 1
//   - R ← accum

module mod_mul (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,       // assert for one cycle to begin multiplication
    input  wire [255:0] A,           // multiplicand
    input  wire [255:0] B,           // multiplier
    output reg  [255:0] R,           // result = (A * B) mod p
    output reg          done         // pulses high for one cycle when R is valid
);
    // secp256k1 prime p
    localparam [255:0] P_CONST =
        256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    // Internal registers
    reg [255:0] accum;        // running accumulator
    reg [255:0] base_reg;     // running base = A * 2^i mod p
    reg [255:0] mult_reg;     // shifting copy of B
    reg [7:0]   count;        // iteration count 0..255
    reg         busy;         // 1 while multiplication in progress

    // Wires for combinational mod_add results
    wire [255:0] sum_accum_base;  // (accum + base_reg) mod p
    wire [255:0] sum_base_double; // (base_reg + base_reg) mod p

    // Instantiate two mod_add units (pure combinational)
    mod_add add_accum_base (
        .A(accum),
        .B(base_reg),
        .R(sum_accum_base)
    );

    mod_add add_base_double (
        .A(base_reg),
        .B(base_reg),
        .R(sum_base_double)
    );

    // Sequential FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum     <= 256'd0;
            base_reg  <= 256'd0;
            mult_reg  <= 256'd0;
            count     <= 8'd0;
            R         <= 256'd0;
            done      <= 1'b0;
            busy      <= 1'b0;
        end else begin
            if (start && !busy) begin
                // Load inputs and begin
                accum    <= 256'd0;
                base_reg <= A;
                mult_reg <= B;
                count    <= 8'd0;
                busy     <= 1'b1;
                done     <= 1'b0;
            end else if (busy) begin
                if (count == 8'd255) begin
                    // Final iteration: include bit 255 of original B
                    if (mult_reg[0]) begin
                        R <= sum_accum_base;
                    end else begin
                        R <= accum;
                    end
                    busy <= 1'b0;
                    done <= 1'b1;
                end else begin
                    // Normal iteration
                    if (mult_reg[0]) begin
                        accum <= sum_accum_base;
                    end else begin
                        accum <= accum;
                    end
                    base_reg <= sum_base_double;
                    mult_reg <= mult_reg >> 1;
                    count    <= count + 8'd1;
                end
            end else begin
                // Idle / not busy
                done <= 1'b0;
            end
        end
    end
endmodule
