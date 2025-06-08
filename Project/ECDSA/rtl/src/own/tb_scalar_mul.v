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

        // New scalar_mul test vectors
        // 1) k = 0x48d609a1707b040f841e68f39ede58adca4c75a55925a68b9486fdc19d34b833, P = G
        check_mul(
            256'h48d609a1707b040f841e68f39ede58adca4c75a55925a68b9486fdc19d34b833,
            256'h79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798,
            256'h483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8,
            1'b0,
            256'h882f2f952e5edaf3358caa809d1d257e97b0a218a2ac564d4ce75f5836bad700,
            256'he57a34cf3374089ff2cc2915e5088264bd5ae47a4aa53f25114359f96fa622b5,
            1'b0
        );

        // 2) k = 0x4a019c8985f28c492d855551a95880dca452ff2de3365888c110f02756ab748e, P = G
        check_mul(
            256'h4a019c8985f28c492d855551a95880dca452ff2de3365888c110f02756ab748e,
            256'h79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798,
            256'h483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8,
            1'b0,
            256'hc36f3030440c42b6097dffa8e19ff9390362c140813243bae11e19f548c4c08,
            256'h3d92f41b8c513613e3e3d5c34afc0356eedfd8b009a0b935bb693c29095c1cd7,
            1'b0
        );

        // 3) k = 0xeb7d15c91943322d52adceb49a0935de9e035003ce58ab033c573acebf5a6f39, P = G
        check_mul(
            256'heb7d15c91943322d52adceb49a0935de9e035003ce58ab033c573acebf5a6f39,
            256'h79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798,
            256'h483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8,
            1'b0,
            256'h3be8d91b4c9aa49d86d209b18de8a8da1c8f337d0f1e56b12dcf41b161a2ac1b,
            256'h17d775a1d243979fa659f365b63f461ddab50283b400055988bd56419ae5c09d,
            1'b0
        );

        // 4) k = 0xc923d186078acbbbfd29b52ab1d6d9efc0eb582ecbf570da8352e26898aa426f, P = previous result
        check_mul(
            256'hc923d186078acbbbfd29b52ab1d6d9efc0eb582ecbf570da8352e26898aa426f,
            256'h882f2f952e5edaf3358caa809d1d257e97b0a218a2ac564d4ce75f5836bad700,
            256'he57a34cf3374089ff2cc2915e5088264bd5ae47a4aa53f25114359f96fa622b5,
            1'b0,
            256'hb7d59381097f9511e2ea9ddf57c31495ca86f4e990157d046c6b7768c048b12b,
            256'h7e57e005f53874f3ef916e722e2befca3108b806942ad4b4ad47aaa6596c918c,
            1'b0
        );

        $display("All scalar_mul tests passed.");
        $finish;
    end
endmodule
