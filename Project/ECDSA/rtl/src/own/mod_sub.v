// File: src/mod_sub.v
// ──────────────────────────────────────────────────────────────────────────
// Compute R = (A – B) mod p, where p = 0xFFFFFFFF…FC2F (secp256k1 prime).
// If A ≥ B:   R = A – B
// Else (A < B):  R = p – (B – A)
// Fully combinational, synthesizable, and never overflows 256 bits.
// ──────────────────────────────────────────────────────────────────────────

module mod_sub (
    input  wire [255:0] A,
    input  wire [255:0] B,
    output wire [255:0] R
);
    // secp256k1 prime p
    localparam [255:0] P_CONST = 256'h
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    // Compare A and B
    wire a_ge_b = (A >= B);

    // When B > A: compute (B – A) safely in 256 bits
    wire [255:0] diff_ba = B - A;

    // When A ≥ B: compute (A – B)
    wire [255:0] diff_ab = A - B;

    // If A ≥ B → R = A − B; else R = p − (B − A)
    assign R = a_ge_b
               ? diff_ab
               : (P_CONST - diff_ba);
endmodule
