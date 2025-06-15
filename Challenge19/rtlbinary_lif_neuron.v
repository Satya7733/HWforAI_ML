// File: rtl/binary_lif_neuron.v
`timescale 1ns/1ps
module binary_lif_neuron #(
    parameter integer W            = 8,   // total fixed-point width
    parameter integer FRAC_BITS    = 5,   // bits to right of binary point
    // λ = LAMBDA_NUM / LAMBDA_DEN  (0 < λ ≤ 1.0)
    parameter integer LAMBDA_NUM   =  8,
    parameter integer LAMBDA_DEN   = 10,
    // θ (threshold) in same Qm.f format
    parameter integer THRESH       = 20,  // e.g. 20/2^FRAC = 0b10100 ≈ 2.5
    // reset value after spike (often 0)
    parameter integer RESET_VAL    =  0
)(
    input  wire                  clk,
    input  wire                  rst_n,   // active-low synchronous reset
    input  wire                  in_bit,  // binary input I(t)
    output reg                   spike    // output S(t)
);
    // internal potential register
    reg [W-1:0] pot;
    // wide product to hold λ·P
    wire [W+clog2(LAMBDA_NUM)-1:0] leak_mult;
    assign leak_mult = pot * LAMBDA_NUM;

    // next potential before threshold/reset
    wire [W-1:0] next_pot =
        (leak_mult / LAMBDA_DEN) + in_bit;  // add binary input (0/1)

    // sequential logic
    always @(posedge clk) begin
        if (!rst_n) begin
            pot   <= '0;
            spike <= 1'b0;
        end else begin
            spike <= (next_pot >= THRESH);
            pot   <= spike ? RESET_VAL[W-1:0] : next_pot;
        end
    end

    // ----------------------------------------------------------------
    // Function: ceiling log2 -- for generic product width computation
    // ----------------------------------------------------------------
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value-1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction
endmodule
