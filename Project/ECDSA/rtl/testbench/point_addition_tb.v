`timescale 1ns / 1ps
module point_addition_tb();
  parameter n = 256;

  reg  clk;
  reg  reset;
  reg  [n-1:0] p;
  reg  [n-1:0] x1, y1, x2, y2;
  wire [n-1:0] x3, y3;
  wire         result_ready, infinity;

  // Instantiate the Device Under Test
  point_addition #(n) dut (
    .clk(clk),
    .reset(reset),
    .p(p),
    .x1(x1), .y1(y1),
    .x2(x2), .y2(y2),
    .x3(x3), .y3(y3),
    .result(result_ready),
    .infinity(infinity)
  );

  // Clock generator: 10 ns period
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    // 1) Set P, Q, and p first
    p  = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F; 
    x1 = 256'h2f57ca28f445cdb0725ca0ff4b6378f30275533c3573cbc3154f1c2248cc7be1;
    y1 = 256'h223085e9ab766f2eea0a2bf360f03bb270f01aa5a43832c38b6f0ff19d4b0523;
    x2 = 256'h6530a8482ae55b608fc540591ec96bb5b4dc52666216ea912efdd267c4f058cf;
    y2 = 256'hb2e59c0fe07116d746ea81811ef6f1e456d9b83c6b80e06f9c8ffc76a74cce9e;

    // 2) Hold in reset for one cycle while P/Q settle
    reset <= 1;
    #12;       // wait 12 ns so that x1..y2 are stable by the time clock rises
    reset <= 0;

    // 3) Wait for the FSM to assert result_ready (or infinity)
    wait(result_ready == 1 || infinity == 1);

    #20;  // Give one extra cycle so x3,y3 latch
    $display("\n======= FINAL OUTPUT =======");
    $display("P = (%h, %h)", x1, y1);
    $display("Q = (%h, %h)", x2, y2);
    $display("Computed P+Q = (%h, %h)", x3, y3);
    $display("------------------------------");
    $display("Expected x3 = ce0f40f6a9ccee1733464750db7f33296d061208311f6057de30c27fd899035b");
    $display("Expected y3 = 1946246d453305c2c45be9b76942bec76f4676cc7b3c0bb37acb3aa28a022301");
    $display("==============================\n");

    $stop;
  end
endmodule
