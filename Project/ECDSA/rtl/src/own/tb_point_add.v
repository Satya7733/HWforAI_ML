// File: tb/tb_point_add.v
// Testbench for point_add.v – only Custom Test Case 2 retained

`timescale 1ns/1ps

module tb_point_add;
    reg           clk, rst_n;
    reg           start;
    reg  [255:0]  x1, y1;
    reg           inf1;
    reg  [255:0]  x2, y2;
    reg           inf2;

    wire [255:0]  x3, y3;
    wire          inf3, done;

    // Instantiate point_add
    point_add uut (
        .clk   (clk),
        .rst_n (rst_n),
        .start (start),
        .x1    (x1),
        .y1    (y1),
        .inf1  (inf1),
        .x2    (x2),
        .y2    (y2),
        .inf2  (inf2),
        .done  (done),
        .x3    (x3),
        .y3    (y3),
        .inf3  (inf3)
    );

    // Custom input P
    localparam [255:0] Px2 =
        256'hC48DABA7B27AB5C595B73AEE10876E8A11D1EC1F67B7E33D5A492E24818CCDF7;
    localparam [255:0] Py2 =
        256'h7C9BC7B7CDADCAA5325DC4D4953FF2A82A2D7AB0BE2C7B692A487248BAB8EC48;

    // Custom input Q
    localparam [255:0] Qx2 =
        256'h954FCF916816263A4645F192CF54E79DAF476AC620639DF7800F4A23ABD3FE87;
    localparam [255:0] Qy2 =
        256'h5FB35F6BF09803384C6B14BB58DD8D9D8658DAE8DAFB76DD11F8622A139BBCE0;

    // Expected R = P + Q
    localparam [255:0] Rx2_expected =
        256'hDFED5FA88334F4C3A78EF0598249397CBFC05F9A80A15629DF8F00868B6D2B0A;
    localparam [255:0] Ry2_expected =
        256'h0E14B29F022BD91999B61A06732E4CB8DB28074264B31CA70882428DE6CDD79C4;
    localparam         Rinf2_expected = 1'b0;

    // Clock: 10 ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task check_add2;
        begin
            x1   = Px2;  y1   = Py2;  inf1 = 1'b0;
            x2   = Qx2;  y2   = Qy2;  inf2 = 1'b0;
            #10; start = 1'b1;
            #10; start = 1'b0;

            wait (done == 1'b1);
            #1;

            if (inf3 !== Rinf2_expected ||
                (inf3 == 1'b0 && (x3 !== Rx2_expected || y3 !== Ry2_expected))) begin
                $display("FAIL: Expected (%064h,%064h,inf=%b), Got (%064h,%064h,inf=%b)",
                         Rx2_expected, Ry2_expected, Rinf2_expected,
                         x3,            y3,            inf3);
                $finish;
            end else begin
                $display("PASS");
            end
            #10;
        end
    endtask

    initial begin
        rst_n = 1'b0;
        start = 1'b0;
        x1    = 256'd0; y1 = 256'd0; inf1 = 1'b0;
        x2    = 256'd0; y2 = 256'd0; inf2 = 1'b0;
        #20;
        rst_n = 1'b1;
        #10;

        // Only Custom Test Case 2:
        check_add2();

        $display("Testbench finished.");
        $finish;
    end
endmodule
