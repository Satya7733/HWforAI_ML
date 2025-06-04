// File: tb/tb_mod_inv.v
// Testbench for mod_inv.v
// Verifies that A * inv(A) mod p == 1 for several values.

`timescale 1ns/1ps

module tb_mod_inv;
    reg           clk, rst_n;
    reg           start_inv;
    reg  [255:0]  A;
    wire [255:0]  invA;
    wire          done_inv;

    // Instantiate mod_inv
    mod_inv uut_inv (
        .clk   (clk),
        .rst_n (rst_n),
        .start (start_inv),
        .A     (A),
        .R     (invA),
        .done  (done_inv)
    );

    // Instantiate a mod_mul to check A * invA mod p == 1
    reg            mul_start;
    reg  [255:0]   mul_a, mul_b;
    wire [255:0]   mul_r;
    wire           done_mul;

    mod_mul uut_mul (
        .clk   (clk),
        .rst_n (rst_n),
        .start (mul_start),
        .A     (mul_a),
        .B     (mul_b),
        .R     (mul_r),
        .done  (done_mul)
    );

    // secp256k1 prime p
    parameter [255:0] P_CONST =
        256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    // Expected inverse of 2: (p + 1) / 2
    parameter [255:0] INV2 =
        256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFE18;

    // Expected inverse of (p - 1) is (p - 1)
    parameter [255:0] INV_P_MINUS_1 = P_CONST - 256'h1;

    // Task: compute inv(A), then check A * inv(A) mod p == 1
    task check_inv;
        input [255:0] Ain;
        input [255:0] expected_inv;
        reg   [255:0] check_product;
        begin
            // 1) Launch mod_inv
            A = Ain;
            #10;
            start_inv = 1'b1;
            #10;
            start_inv = 1'b0;

            // Wait for done_inv
            wait (done_inv == 1'b1);
            #1;

            // Check inv(A) directly
            if (invA !== expected_inv) begin
                $display("");
                $display("**********************************");
                $display("FAIL: A = %h", Ain);
                $display("  Expected inv(A) = %h", expected_inv);
                $display("  Got            = %h", invA);
                $display("**********************************");
                $finish;
            end else begin
                $display("PASS (direct): inv(%h) = %h", Ain, invA);
            end

            // 2) Check A * inv(A) mod p == 1
            mul_a = Ain;
            mul_b = invA;
            #10;
            mul_start = 1'b1;
            #10;
            mul_start = 1'b0;

            wait (done_mul == 1'b1);
            #1;
            check_product = mul_r;

            if (check_product !== 256'h1) begin
                $display("");
                $display("**********************************");
                $display("FAIL (verify): A = %h", Ain);
                $display("  inv(A) = %h", invA);
                $display("  A * inv(A) mod p = %h  (should be 1)", check_product);
                $display("**********************************");
                $finish;
            end else begin
                $display("PASS (verify): %h * %h mod p = 1", Ain, invA);
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
        rst_n     = 1'b0;
        start_inv = 1'b0;
        A         = 256'd0;
        mul_start = 1'b0;
        mul_a     = 256'd0;
        mul_b     = 256'd0;
        #20;
        rst_n = 1'b1;
        #10;

        // Test 1: A = 1 → inv(1) = 1
        check_inv(256'h1, 256'h1);

        // Test 2: A = 2 → inv(2) = INV2
        check_inv(256'h2, INV2);

        // Test 3: A = p - 1 → inv(p - 1) = p - 1
        check_inv(P_CONST - 256'h1, INV_P_MINUS_1);

        $display("");
        $display("All mod_inv tests passed.");
        $finish;
    end
endmodule
