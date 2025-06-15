/* File: tb_mod_sub.v
 Testbench for mod_sub.v */

`timescale 1ns/1ps

module tb_mod_sub;
    reg  [255:0] A, B;
    wire [255:0] R;

    // Instantiate the mod_sub module
    mod_sub uut (
        .A(A),
        .B(B),
        .R(R)
    );

    // secp256k1 prime p
    parameter [255:0] P_CONST =
        256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    // Task to compare expected vs. actual result and print pass/fail
    task check;
        input [255:0] exp;
        begin
            #1; // wait for combinational output to settle
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
        end
    endtask

    initial begin
        // Test 1: 0 - 0 = 0
        A = 256'h0;
        B = 256'h0;
        check(256'h0);

        // Test 2: 1 - 1 = 0
        A = 256'h1;
        B = 256'h1;
        check(256'h0);

        // Test 3: 0 - 1 = p - 1
        A = 256'h0;
        B = 256'h1;
        check(P_CONST - 256'h1);

        // Test 4: (p - 1) - (p - 1) = 0
        A = P_CONST - 256'h1;
        B = P_CONST - 256'h1;
        check(256'h0);

        // Test 5: 0x1234 - 0x0567 = 0x0CCD
        A = 256'h0000000000000000000000000000000000000000000000000000000000001234;
        B = 256'h0000000000000000000000000000000000000000000000000000000000000567;
        check(256'h0000000000000000000000000000000000000000000000000000000000000CCD);

        // Test 6: 0x1 - 0x2 = p - 1
        A = 256'h1;
        B = 256'h2;
        check(P_CONST - 256'h1);

        // Test 7: (p - 10) - (p - 20) = 10
        A = P_CONST - 256'hA;   // p - 10
        B = P_CONST - 256'h14;  // p - 20
        check(256'hA);

        $display("");
        $display("All mod_sub tests passed.");
        $finish;
    end
endmodule
