`timescale 1ns/1ps

module tb_scalar_mul_serial_top;

  // Clock & reset
  reg         clk;
  reg         rst_n;

  // Serial-bus interface signals
  reg         wr_en, rd_en;
  reg  [4:0]  addr;
  reg  [31:0] wr_data;
  wire [31:0] rd_data;
  wire        rd_valid;

  // Scalar-mul handshake
  wire        done;

  // Instantiate DUT
  scalar_mul_serial_top dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .wr_en   (wr_en),
    .rd_en   (rd_en),
    .addr    (addr),
    .wr_data (wr_data),
    .rd_data (rd_data),
    .rd_valid(rd_valid),
    .done    (done)
  );

  //--------------------------------------------------------------------------
  // Test-vector definitions
  //--------------------------------------------------------------------------

  // secp256k1 base point G
  localparam [255:0] Gx = 256'h79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  localparam [255:0] Gy = 256'h483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;

  // 2·G
  localparam [255:0] G2x = 256'hC6047F9441ED7D6D3045406E95C07CD85C778E4B8CEF3CA7ABAC09B95C709EE5;
  localparam [255:0] G2y = 256'h1AE168FEA63DC339A3C58419466CEAE E F7F632653266D0E1236431A950CFE52A;

  //--------------------------------------------------------------------------
  // Bus‐access tasks
  //--------------------------------------------------------------------------

  // Write one 32-bit word at addr
  task write_word(input [4:0] a, input [31:0] d);
  begin
    @(posedge clk);
      wr_en   <= 1;
      addr    <= a;
      wr_data <= d;
    @(posedge clk);
      wr_en   <= 0;
      addr    <= 0;
      wr_data <= 0;
  end
  endtask

  // Read one 32-bit word at addr → data
  task read_word(input [4:0] a, output [31:0] data);
  begin
    @(posedge clk);
      rd_en <= 1;
      addr  <= a;
    @(posedge clk);
      rd_en <= 0;
      addr  <= 0;
      if (!rd_valid) $fatal("Read @%0d: rd_valid not asserted", a);
      data = rd_data;
  end
  endtask

  //--------------------------------------------------------------------------
  // Perform a scalar-mul test
  //--------------------------------------------------------------------------

  task do_test(
    input [255:0] k,
    input [255:0] Px, input [255:0] Py, input Pinf,
    input [255:0] expX, input [255:0] expY, input expInf
  );
    integer i;
    reg [31:0] slice;
    reg [31:0] xw [0:7], yw [0:7];
    reg [255:0] gotX, gotY;
    reg        gotInf;
  begin
    // 1) load k, Px, Py, Pinf
    for (i = 0; i < 8; i = i+1) begin
      slice = k[32*i +: 32];
      write_word(i, slice);
    end
    for (i = 0; i < 8; i = i+1) begin
      slice = Px[32*i +: 32];
      write_word(8+i, slice);
    end
    for (i = 0; i < 8; i = i+1) begin
      slice = Py[32*i +: 32];
      write_word(16+i, slice);
    end
    write_word(24, {31'd0, Pinf});

    // 2) start
    write_word(25, 32'h1);

    // 3) wait for done pulse
    @(posedge done);

    // 4) read back Xout, Yout, inf_out
    for (i = 0; i < 8; i = i+1)
      read_word(i, xw[i]);
    for (i = 0; i < 8; i = i+1)
      read_word(8+i, yw[i]);
    read_word(16, slice);
    gotInf = slice[0];

    // reassemble
    gotX = { xw[7], xw[6], xw[5], xw[4], xw[3], xw[2], xw[1], xw[0] };
    gotY = { yw[7], yw[6], yw[5], yw[4], yw[3], yw[2], yw[1], yw[0] };

    // 5) compare & report
    if (gotInf !== expInf || gotX !== expX || gotY !== expY) begin
      $display("FAIL k=%h:", k);
      $display("   Expected (X,Y,inf) = (%h,%h,%b)", expX, expY, expInf);
      $display("        Got     (X,Y,inf) = (%h,%h,%b)", gotX, gotY, gotInf);
    end else begin
      $display("PASS k=%0h", k);
    end

    // little gap
    #20;
  end
  endtask

  //--------------------------------------------------------------------------
  // Clock gen & reset
  //--------------------------------------------------------------------------

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    // reset
    rst_n = 0;
    wr_en = 0; rd_en = 0;
    addr  = 0; wr_data = 0;
    #20;
    rst_n = 1;
    #20;

    // Run tests
    do_test(
      256'd0,    // k
      Gx, Gy,    // P
      1'b0,      // Pinf
      256'd0,    // 0·P → ∞
      256'd0,
      1'b1
    );
    do_test(
      256'd1,
      Gx, Gy,
      1'b0,
      Gx, Gy,
      1'b0
    );
    do_test(
      256'd2,
      Gx, Gy,
      1'b0,
      G2x, G2y,
      1'b0
    );

    $display("All done.");
    $finish;
  end

endmodule
