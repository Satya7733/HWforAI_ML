// Updated FSM-based point addition with debug-friendly combinational multipliers/inverse
module point_addition #(parameter n = 256)(
  input              clk,
  input              reset,
  input  [n-1:0]     p,
  input  [n-1:0]     x1, y1,
  input  [n-1:0]     x2, y2,
  output reg [n-1:0] x3,
  output reg [n-1:0] y3,
  output reg         result,
  output reg         infinity
);

  // Internal registers
  reg  [n-1:0] y_diff, x_diff;
  reg  [n-1:0] lambda, lambda2, x1x2, x1x3_diff;
  reg  [n-1:0] mult_a, mult_b;
  reg           inv_start;
  wire [n-1:0]  inv_result;
  wire          inv_done;
  wire [n-1:0]  mult_result;
  wire          mult_done;

  // FSM states (4-bit) for extra states
  parameter IDLE    = 4'd0,
            CALC_INV= 4'd1,
            WAIT_INV= 4'd2,
            CALC_L1 = 4'd3,
            WAIT_L1 = 4'd4,
            CALC_L2 = 4'd5,
            WAIT_L2 = 4'd6,
            CALC_X3 = 4'd7,
            CALC_Y  = 4'd8,
            WAIT_Y  = 4'd9,
            DONE    = 4'd10;
  reg [3:0] state;

  // Dummy combinational multiplier (1-cycle) for debugging
  module debug_mul #(parameter m = n)(
    input  clk,
    input  reset,
    input  enable,
    input  [m-1:0] A,
    input  [m-1:0] B,
    input  [m-1:0] modp,
    output reg [m-1:0] M,
    output reg        flag
  );
    always @(posedge clk or posedge reset) begin
      if (reset) begin
        M    <= 0;
        flag <= 0;
      end else if (enable) begin
        M    <= (A * B) % modp;
        flag <= 1;
      end else begin
        flag <= 0;
      end
    end
  endmodule

  // Dummy combinational inverse (1-cycle) for debugging
  module debug_inv #(parameter m = n)(
    input  clk,
    input  reset,
    input  enable,
    input  [m-1:0] A,
    input  [m-1:0] modp,
    output reg [m-1:0] X,
    output reg        ready
  );
    function [m-1:0] inv_f;
      input [m-1:0] in;
      input [m-1:0] mp;
      begin
        // Fermat's little theorem for prime p: in^(p-2) mod p
        inv_f = 1;
        // naive pow (inefficient but single-cycle for small test only)
        inv_f = in;
        inv_f = inv_f ** (mp - 2) % mp;
      end
    endfunction
    always @(posedge clk or posedge reset) begin
      if (reset) begin
        X     <= 0;
        ready <= 0;
      end else if (enable) begin
        X     <= inv_f(A, modp);
        ready <= 1;
      end else begin
        ready <= 0;
      end
    end
  endmodule

  // Instantiate debug modules
  wire mul_ready;
  reg  mul_enable;
  debug_mul #(n) mul_inst (
    .clk(clk), .reset(reset), .enable(mul_enable),
    .A(mult_a), .B(mult_b), .modp(p), .M(mult_result), .flag(mul_ready)
  );

  wire inv_ready;
  reg  inv_en;
  debug_inv #(n) inv_inst (
    .clk(clk), .reset(reset), .enable(inv_en),
    .A(x_diff), .modp(p), .X(inv_result), .ready(inv_ready)
  );

  // FSM
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state      <= IDLE;
      result     <= 0;
      infinity   <= 0;
      inv_en     <= 0;
      mul_enable <= 0;
      x3         <= 0;
      y3         <= 0;
      y_diff     <= 0;
      x_diff     <= 0;
      lambda     <= 0;
      lambda2    <= 0;
      x1x2       <= 0;
      x1x3_diff  <= 0;
      mult_a     <= 0;
      mult_b     <= 0;
    end else begin
      case (state)
        IDLE: begin
          result   <= 0;
          infinity <= 0;
          if ((x1 == x2) && ((y1 + y2) % p == 0)) begin
            infinity <= 1;
            x3       <= 0;
            y3       <= 0;
            state    <= DONE;
          end else begin
            // compute diffs (blocking)
            y_diff = (y2 >= y1) ? (y2 - y1) : (y2 + p - y1);
            x_diff = (x2 >= x1) ? (x2 - x1) : (x2 + p - x1);
            $display("[IDLE] y_diff=%h, x_diff=%h", y_diff, x_diff);
            inv_en  <= 1;
            state   <= CALC_INV;
          end
        end

        CALC_INV: begin
          inv_en <= 0;
          state  <= WAIT_INV;
        end

        WAIT_INV: begin
          if (inv_ready) begin
            x_diff <= inv_result;
            $display("[WAIT_INV] x_diff_inv=%h", inv_result);
            lambda <= y_diff * inv_result % p;
            $display("[WAIT_INV] λ=%h", lambda);
            state  <= CALC_L1;
          end
        end

        CALC_L1: begin
          // λ already computed combinationally; compute λ²
          lambda2 <= lambda * lambda % p;
          $display("[CALC_L1] λ²=%h", lambda2);
          x1x2    <= (x1 + x2) % p;
          state   <= CALC_L2;
        end

        CALC_L2: begin
          // now x3 = λ² - x1 - x2 mod p
          x3 <= (lambda2 >= x1x2) ? (lambda2 - x1x2) % p : (lambda2 + p - x1x2) % p;
          $display("[CALC_L2] x3=%h", x3);
          x1x3_diff <= (x1 >= x3) ? (x1 - x3) : (x1 + p - x3);
          $display("[CALC_L2] x1-x3=%h", x1x3_diff);
          state <= CALC_X3;
        end

        CALC_X3: begin
          // y3 = λ*(x1 - x3) - y1 mod p
          y3 <= (lambda * x1x3_diff % p >= y1) 
                 ? (lambda * x1x3_diff % p - y1) % p 
                 : (lambda * x1x3_diff % p + p - y1) % p;
          $display("[CALC_X3] y3=%h", y3);
          result <= 1;
          state  <= DONE;
        end

        DONE: begin
          // stay here a cycle so TB can sample
          state <= IDLE;
        end

      endcase
    end
  end
endmodule
