// rtl/scalar_mult.v
module scalar_mult(
    input  logic         clk,
    input  logic         rst_n,
    input  logic [255:0] k,
    input  logic [255:0] Px, Py,
    output logic [255:0] Rx, Ry,
    output logic         valid
);

  //------------------------------------------------------------------------
  // FSM states
  typedef enum logic [1:0] {
    S_IDLE,    // load inputs
    S_CALC,    // one bit of double-and-add
    S_DONE     // result ready
  } state_t;

  state_t            state;
  logic [255:0]      k_reg;
  logic [255:0]      Ax, Ay;       // “addend” point (starts at P)
  logic [255:0]      Rx_reg, Ry_reg; // accumulator (starts at ∞)
  integer            bit_cnt;

  // synchronously run the double-and-add loop
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state    <= S_IDLE;
      k_reg    <= '0;
      Ax       <= '0;
      Ay       <= '0;
      Rx_reg   <= '0;
      Ry_reg   <= '0;
      bit_cnt  <= 0;
      Rx       <= '0;
      Ry       <= '0;
      valid    <= 0;
    end else begin
      case (state)

        // load inputs and init
        S_IDLE: begin
          k_reg   <= k;
          Ax      <= Px;
          Ay      <= Py;
          // define “point at infinity” as (0,0); your point_add must handle it
          Rx_reg  <= 0;
          Ry_reg  <= 0;
          bit_cnt <= 0;
          valid   <= 0;
          state   <= S_CALC;
        end

        // for each bit of k_reg (LSB first):
        //   if 1 → Rx_reg = Rx_reg + Ax, Ry_reg = Ry_reg + Ay
        //   then Ax = 2·Ax, Ay = 2·Ay
        //   shift k_reg right
        S_CALC: begin
          if (bit_cnt < 256) begin
            if (k_reg[0]) begin
              // conditional accumulate
              { Rx_reg, Ry_reg } <= point_add(Rx_reg, Ry_reg, Ax, Ay);
            end
            // always double
            { Ax, Ay } <= point_double(Ax, Ay);

            k_reg   <= k_reg >> 1;
            bit_cnt <= bit_cnt + 1;
          end else begin
            // done
            Rx    <= Rx_reg;
            Ry    <= Ry_reg;
            valid <= 1;
            state <= S_DONE;
          end
        end

        // hold result
        S_DONE: begin
          // nothing
        end

      endcase
    end
  end

  //------------------------------------------------------------------------
  // point_add: combinational EC point addition (P + Q)
  //   implement the usual slope = (y2 - y1)*inv_mod(x2 - x1, p) mod p, etc.
  //   must handle P==(0,0) or Q==(0,0) as “point at infinity”
  function automatic logic [511:0] point_add(
    input logic [255:0] x1, y1,
    input logic [255:0] x2, y2
  );
    // { x3, y3 }
    // -- stub: replace with your real implementation --
    logic [255:0] x3, y3;
    begin
      // TODO: replace with full EC add
      x3 = x2;
      y3 = y2;
      point_add = { x3, y3 };
    end
  endfunction

  //------------------------------------------------------------------------
  // point_double: combinational EC point doubling (2·P)
  function automatic logic [511:0] point_double(
    input logic [255:0] x1, y1
  );
    // { x3, y3 }
    // -- stub: replace with your real implementation --
    logic [255:0] x3, y3;
    begin
      // TODO: replace with full EC double
      x3 = x1;
      y3 = y1;
      point_double = { x3, y3 };
    end
  endfunction

endmodule
