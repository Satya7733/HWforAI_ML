// File: tb/tb_binary_lif_neuron.v
`timescale 1ns/1ps
module tb_binary_lif_neuron;

    // ----------------------------
    // Parameters identical to DUT
    // ----------------------------
    localparam W           = 8;
    localparam FRAC_BITS   = 5;
    localparam LNUM        = 8;
    localparam LDEN        = 10;
    localparam THRESH      = 20;
    localparam RESET_VAL   =  0;

    // ----------------------------
    // DUT signals
    // ----------------------------
    reg  clk = 0;
    reg  rst_n = 0;
    reg  in_bit = 0;
    wire spike;

    // instantiate DUT
    binary_lif_neuron #(
        .W(W), .FRAC_BITS(FRAC_BITS),
        .LAMBDA_NUM(LNUM), .LAMBDA_DEN(LDEN),
        .THRESH(THRESH), .RESET_VAL(RESET_VAL)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_bit(in_bit),
        .spike(spike)
    );

    // clock generator
    always #5 clk = ~clk;

    // high-level golden model variables (double precision)
    real pot_g = 0.0;
    real lambda = LNUM * 1.0 / LDEN;
    real thresh = THRESH / (1 << FRAC_BITS);

    // stimulus + scoreboard
    integer i;
    initial begin
        // reset for 2 clocks
        repeat (2) @(posedge clk);
        rst_n <= 1;
        @(posedge clk);

        // 32-cycle test
        for (i = 0; i < 32; i = i + 1) begin
            // deterministic pseudo-random binary input
            in_bit <= (i==2)||(i==3)||(i==8)||(i==9)||(i==16);
            @(posedge clk);

            // compute golden reference
            pot_g = lambda * pot_g + in_bit;
            if (pot_g >= thresh) begin
                if (!spike) $fatal("Spike MISSED at t=%0d", i);
                pot_g = RESET_VAL / (1<<FRAC_BITS);
            end else if (spike) begin
                $fatal("Spike FALSE-POSITIVE at t=%0d", i);
            end
        end

        $display("All checks passed!");
        $finish;
    end
endmodule
