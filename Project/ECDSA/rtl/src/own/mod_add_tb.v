// File: tb/tb_mod_add.v
// Testbench for mod_add.v

`timescale 1ns/1ps

module tb_mod_add;
    reg  [255:0] A, B;
    wire [255:0] R;

    // Instantiate the mod_add module
    mod_add uut (
        .A(A),
        .B(B),
        .R(R)
    );

    // secp256k1 prime p
    parameter [255:0] P_CONST =
        256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    // Simple task to compare expected vs. actual result
    task check;
        input [255:0] exp;
        begin
            #1; // wait for combinational logic to settle
            if (R !== exp) begin
                $display("FAIL: A = %h, B = %h", A, B);
                $display("      Expected R = %h", exp);
                $display("      Got      R = %h", R);
                $finish;
            end else begin
                $display("PASS: A = %h, B = %h  → R = %h", A, B, R);
            end
        end
    endtask

    initial begin
        // Test 1: 0 + 0 = 0
        A = 256'h0;
        B = 256'h0;
        check(256'h0);

        // Test 2: 1 + 1 = 2
        A = 256'h1;
        B = 256'h1;
        check(256'h2);

        // Test 3: (p - 1) + 1 = 0  (wrap around)
        A = P_CONST - 256'h1;
        B = 256'h1;
        check(256'h0);

        // Test 4: (p - 2) + 3 = 1  (wrap around)
        A = P_CONST - 256'h2;
        B = 256'h3;
        check(256'h1);

        // Test 5: 0x1234 + 0xFEDC = 0x11110
        A = 256'h0000000000000000000000000000000000000000000000000000000000001234;
        B = 256'h000000000000000000000000000000000000000000000000000000000000FEDC;
        check(256'h0000000000000000000000000000000000000000000000000000000000011110);

        // Test 6: (p/2) + (p/2 - 1) = p - 1 (no wrap)
        // Compute p/2 and p/2 - 1 manually:
        //   p = 0xFFFF...FC2F
        //   p/2 = 0x7FFF...FE97 (right-shift by 1, rounding floor)
        //   (p/2 - 1) = 0x7FFF...FE96
        //   Sum = 0xFFFF...FC2D  (== p - 1)
        A = 256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFF97;
        B = 256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFF96;
        check(P_CONST - 256'h1);

        $display("All mod_add tests passed.");
        $finish;
    end
endmodule
