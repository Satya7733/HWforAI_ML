// File: tb/tb_scalar_mul.v
// Testbench for scalar_mul.v to verify k·P on secp256k1

`timescale 1ns/1ps

module tb_scalar_mul;
    reg           clk, rst_n;
    reg           start;
    reg  [255:0]  k;
    reg  [255:0]  Px, Py;
    reg           Pinf;

    wire [255:0]  Xout, Yout;
    wire          inf_out, done;

    // Instantiate scalar_mul
    scalar_mul uut (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (start),
        .k       (k),
        .Px      (Px),
        .Py      (Py),
        .Pinf    (Pinf),
        .done    (done),
        .Xout    (Xout),
        .Yout    (Yout),
        .inf_out (inf_out)
    );

    // Generator G
    localparam [255:0] Gx =
        256'h79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    localparam [255:0] Gy =
        256'h483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;

    // 2·G
    localparam [255:0] _2Gx =
        256'hC6047F9441ED7D6D3045406E95C07CD85C778E4B8CEF3CA7ABAC09B95C709EE5;
    localparam [255:0] _2Gy =
        256'h1AE168FEA63DC339A3C58419466CEAE7F632653266D0E1236431A950CFE52A;

    // 3·G
    localparam [255:0] _3Gx =
        256'hF9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9;
    localparam [255:0] _3Gy =
        256'h388F7B0F632DE8140FE337E62A37F3566500A99934C2231B6CB9FD7584B8E672;

    // Arbitrary point for doubling test
    localparam [255:0] Pdx =
        256'h4A991F7C44E0C3796364193ADBB82DD47964B6431C79A9A3685CA2423C373ACF;
    localparam [255:0] Pdy =
        256'h605EECCB3BFDABDAFF7916274EFB8C992F8F52BCF1BA318BDDBB60915B94D755;

    // 2·P (expected doubling)
    localparam [255:0] D2x =
        256'hF015694A1F7E48E1481CE48190CE72A8FF0CD85E3093274588EB8D46291222CC;
    localparam [255:0] D2y =
        256'h2618750BD614F01D5787BD5CDD4392880F5D929404145EC80DFDA85C03481C8C;

    // Clock: 10 ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Task to check k·(Px,Py, Pinf) == (ExpX,ExpY,ExpInf)
    task check_mul;
        input [255:0] t_k;
        input [255:0] t_Px, t_Py;
        input         t_Pinf;
        input [255:0] ExpX, ExpY;
        input         ExpInf;
        begin
            k     = t_k;
            Px    = t_Px;
            Py    = t_Py;
            Pinf  = t_Pinf;
            #10; start = 1'b1;
            #10; start = 1'b0;

            wait (done == 1'b1);
            #1;

            if (inf_out !== ExpInf ||
                (inf_out == 1'b0 && (Xout !== ExpX || Yout !== ExpY))) begin
                $display("FAIL: k=%h, P=(%h,%h,inf=%b)", t_k, t_Px, t_Py, t_Pinf);
                $display("Expected (%h,%h,inf=%b), Got (%h,%h,inf=%b)",
                         ExpX, ExpY, ExpInf, Xout, Yout, inf_out);
                $finish;
            end else begin
                $display("PASS: k=%h, P=(%h,%h) → (%h,%h)", 
                         t_k, t_Px, t_Py, Xout, Yout);
            end
            #10;
        end
    endtask

    initial begin
        rst_n = 1'b0;
        start = 1'b0;
        k     = 256'd0;
        Px    = 256'd0;
        Py    = 256'd0;
        Pinf  = 1'b1;
        #20;
        rst_n = 1'b1;
        #10;

        // 1) k = 0, P = G → R = ∞
        check_mul(
            256'h0,
            Gx, Gy,
            1'b0,
            256'h0,    // Xout irrelevant
            256'h0,    // Yout irrelevant
            1'b1     // infinity
        );

        // 2) k = 1, P = G → R = G
        check_mul(
            256'h1,
            Gx, Gy,
            1'b0,
            Gx, Gy,
            1'b0
        );

        // 3) k = 2, P = G → R = 2·G
        check_mul(
            256'h2,
            Gx, Gy,
            1'b0,
            _2Gx, _2Gy,
            1'b0
        );

        // 4) k = 3, P = G → R = 3·G
        check_mul(
            256'h3,
            Gx, Gy,
            1'b0,
            _3Gx, _3Gy,
            1'b0
        );

        // 5) k = 2, P = arbitrary Pd → R = 2·Pd (point doubling test)
        check_mul(
            256'h2,
            Pdx, Pdy,
            1'b0,
            D2x, D2y,
            1'b0
        );

        $display("All scalar_mul tests passed.");
        $finish;
    end
endmodule

