
// File: tb/tb_mod_mul.v
// Simple testbench for mod_mul.v

`timescale 1ns/1ps

module tb_mod_mul;
    reg          clk, rst_n;
    reg          start;
    reg  [255:0] A, B;
    wire [255:0] R;
    wire         done;

    // Instantiate the mod_mul module
    mod_mul uut (
        .clk   (clk),
        .rst_n (rst_n),
        .start (start),
        .A     (A),
        .B     (B),
        .R     (R),
        .done  (done)
    );

    // secp256k1 prime p
    parameter [255:0] P_CONST =
        256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    // Task to compare expected vs. actual result
    task check;
        input [255:0] exp;
        begin
            // Wait for done pulse
            wait (done == 1'b1);
            #1; // let R settle
            if (R !== exp) begin
                $display("");
                $display("**********************************");
                $display("FAIL:");
                $display("  A       = %h", A);
                $display("  B       = %h", B);
                $display("  Expected R = %h", exp);
                $display("  Got      R = %h", R);
                $display("**********************************");
                $finish;
            end else begin
                $display("PASS: A = %h, B = %h  → R = %h", A, B, R);
            end
            #5;
        end
    endtask

    // Clock generation: 10 ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        start = 1'b0;
        A     = 256'd0;
        B     = 256'd0;
        #20;
        rst_n = 1'b1;
        #10;

        // Test 1: 0 * 0 = 0
        A = 256'h0; B = 256'h0;
        #10; start = 1'b1;
        #10; start = 1'b0;
        check(256'h0);

        // Test 2: 1 * 1 = 1
        A = 256'h1; B = 256'h1;
        #10; start = 1'b1;
        #10; start = 1'b0;
        check(256'h1);

        // Test 3: 2 * 3 = 6
        A = 256'h2; B = 256'h3;
        #10; start = 1'b1;
        #10; start = 1'b0;
        check(256'h6);

        // Test 4: (p-1) * 2 = (p-1)*2 mod p = p-2
        A = P_CONST - 256'h1;
        B = 256'h2;
        #10; start = 1'b1;
        #10; start = 1'b0;
        check(P_CONST - 256'h2);

        // Test 5: (p-2) * (p-3) mod p
        //    (p-2)*(p-3) = p^2 -5p + 6 ≡ 6 mod p
        A = P_CONST - 256'h2;
        B = P_CONST - 256'h3;
        #10; start = 1'b1;
        #10; start = 1'b0;
        check(256'h6);

        // Test 6: Random-ish small numbers: 0x12345 * 0xFED = 0x12345*0xFED
        //    0x12345 = 74565, 0xFED = 4077 → product = 74565*4077 = 304073, ADJUST:
        //    Actually 74565 * 4077 = 304073 (decimal) → hex = 0x4A419
        A = 256'h0000000000000000000000000000000000000000000000000000000000012345;
        B = 256'h0000000000000000000000000000000000000000000000000000000000000FED;
        #10; start = 1'b1;
        #10; start = 1'b0;
        check(256'h0000000000000000000000000000000000000000000000000000000000121EB1E1);

        $display("");
        $display("All mod_mul tests passed.");
        $finish;
    end
endmodule
