// File: src/mod_add.v
// Computes R = (A + B) mod p, where
// p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F

module mod_add (
    input  [255:0] A,
    input  [255:0] B,
    output [255:0] R
);
    // secp256k1 prime p
    parameter [255:0] P_CONST =
        256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    // Extend to 257 bits so we can detect overflow
    wire [256:0] sum_ext;
    assign sum_ext = {1'b0, A} + {1'b0, B};

    reg  [255:0] R_reg;
    assign R = R_reg;

    always @(*) begin
        if (sum_ext >= {1'b0, P_CONST})
            R_reg = sum_ext[255:0] - P_CONST;
        else
            R_reg = sum_ext[255:0];
    end
endmodule
