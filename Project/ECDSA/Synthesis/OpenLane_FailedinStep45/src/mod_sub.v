// File: src/mod_sub.v
// ──────────────────────────────────────────────────────────────────────────
// Compute R = (A – B) mod p, where p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F.
//   If A ≥ B:   R = A – B
//   Else:       R = p – (B – A)
// Always reduces correctly mod p (no 256-bit underflow).
// ──────────────────────────────────────────────────────────────────────────

module mod_sub (
    input  wire [255:0] A,
    input  wire [255:0] B,
    output reg  [255:0] R
);
    // secp256k1 prime p
    localparam [255:0] P_CONST = 256'h
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    // Compare A and B
    wire a_ge_b    = (A >= B);

    // Compute (B – A) when B > A (no underflow)
    wire [255:0] diff_ba = B - A;

    // Compute (A – B) when A ≥ B
    wire [255:0] diff_ab = A - B;

    always @(*) begin
        if (a_ge_b) begin
            R = diff_ab;
         //  $display("mod_sub: A ≥ B → diff_ab = %h", diff_ab);
        end else begin
            R = P_CONST - diff_ba;
          //  $display("mod_sub: A < B  → p – (B – A) = %h", P_CONST - diff_ba);
        end
    end
endmodule
