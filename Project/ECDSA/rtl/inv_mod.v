// rtl/inv_mod.v
module inv_mod(
    input  logic         clk,
    input  logic         rst_n,
    input  logic [255:0] k,
    input  logic [255:0] m,
    output logic [255:0] inv,
    output logic         valid
);

  //------------------------------------------------------------------------
  // States for our FSM
  typedef enum logic [1:0] {
    S_IDLE,     // load inputs, init registers
    S_CALC,     // perform square-and-multiply
    S_DONE      // result ready
  } state_t;

  state_t            state;
  logic [255:0]      base_reg;
  logic [255:0]      exp_reg;
  logic [255:0]      mod_reg;
  logic [255:0]      result_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // reset everything
      state       <= S_IDLE;
      base_reg    <= 0;
      exp_reg     <= 0;
      mod_reg     <= 0;
      result_reg  <= 0;
      inv         <= 0;
      valid       <= 0;
    end else begin
      case (state)

        //------------------------------------------------------------------
        // IDLE: latch inputs, compute initial values
        //------------------------------------------------------------------
        S_IDLE: begin
          // we want inv = k^(m-2) mod m
          base_reg    <= k % m;          // b = k mod m
          exp_reg     <= m - 2;          // exponent = m-2
          mod_reg     <= m;              // store m
          result_reg  <= 1;              // result = 1
          valid       <= 0;              // not ready yet
          state       <= S_CALC;
        end

        //------------------------------------------------------------------
        // CALC: for each bit of exp, do:
        //   if LSB=1: result = (result * base) % mod
        //   base = (base * base) % mod
        //   exp >>= 1
        //------------------------------------------------------------------
        S_CALC: begin
          if (exp_reg != 0) begin
            // multiply when bit is 1
            if (exp_reg[0])
              result_reg <= (result_reg * base_reg) % mod_reg;
            // else keep result_reg the same

            // always square the base
            base_reg    <= (base_reg * base_reg) % mod_reg;
            // shift exponent
            exp_reg     <= exp_reg >> 1;
          end else begin
            // done: exponent exhausted
            inv   <= result_reg;
            valid <= 1;
            state <= S_DONE;
          end
        end

        //------------------------------------------------------------------
        // DONE: hold the result until next reset
        //------------------------------------------------------------------
        S_DONE: begin
          // nothing more to do
        end

      endcase
    end
  end

endmodule
