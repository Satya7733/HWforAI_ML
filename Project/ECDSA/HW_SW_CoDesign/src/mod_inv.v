// File: src/mod_inv.v
// Computes R = A^(p-2) mod p, where
//   p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
// Uses binary exponentiation: 
//   e = p-2, res = 1, x = A.
//   While (e != 0):
//     if (e[0] == 1) res = (res * x) mod p
//     x = (x * x) mod p
//     e >>= 1
//   R = res

module mod_inv (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,     // pulse to begin inversion
    input  wire [255:0] A,         // value to invert
    output reg  [255:0] R,         // result = A^(p-2) mod p
    output reg          done       // one-cycle pulse when R is valid
);
    // secp256k1 prime p
    localparam [255:0] P_CONST =
        256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    // Exponent = p - 2
    localparam [255:0] EXP_CONST =
        256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2D;

    // State encoding
    localparam IDLE       = 3'd0;
    localparam INIT       = 3'd1;
    localparam BIT_CHECK  = 3'd2;
    localparam MUL_START  = 3'd3;
    localparam MUL_WAIT   = 3'd4;
    localparam SQ_START   = 3'd5;
    localparam SQ_WAIT    = 3'd6;
    localparam DONE       = 3'd7;

    reg [2:0]       state, next_state;
    reg [255:0]     e_reg;      // exponent shifting right
    reg [255:0]     x_reg;      // current base
    reg [255:0]     res_reg;    // current result
    reg             mul_start;  // to drive mod_mul.start
    reg [255:0]     mul_a, mul_b;
    wire [255:0]    mul_r;
    wire            mul_done;

    // Instantiate the single mod_mul
    mod_mul u_mod_mul (
        .clk   (clk),
        .rst_n (rst_n),
        .start (mul_start),
        .A     (mul_a),
        .B     (mul_b),
        .R     (mul_r),
        .done  (mul_done)
    );

    // Sequential: registers and outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            e_reg     <= 256'd0;
            x_reg     <= 256'd0;
            res_reg   <= 256'd0;
            R         <= 256'd0;
            done      <= 1'b0;
            mul_start <= 1'b0;
            mul_a     <= 256'd0;
            mul_b     <= 256'd0;
        end else begin
            state <= next_state;

            // Default: deassert mul_start unless in a START state
            if (state != MUL_START && state != SQ_START)
                mul_start <= 1'b0;

            case (state)
                IDLE: begin
                    done <= 1'b0;
                end

                INIT: begin
                    e_reg   <= EXP_CONST;
                    x_reg   <= A;
                    res_reg <= 256'd1;
                end

                BIT_CHECK: begin
                    // nothing latched here; next_state logic decides
                end

                MUL_START: begin
                    // Begin res = res * x
                    mul_start <= 1'b1;
                    mul_a     <= res_reg;
                    mul_b     <= x_reg;
                end

                MUL_WAIT: begin
                    if (mul_done) begin
                        res_reg <= mul_r;
                    end
                end

                SQ_START: begin
                    // Begin x = x * x
                    mul_start <= 1'b1;
                    mul_a     <= x_reg;
                    mul_b     <= x_reg;
                end

                SQ_WAIT: begin
                    if (mul_done) begin
                        x_reg <= mul_r;
                        e_reg <= e_reg >> 1;
                    end
                end

                DONE: begin
                    R    <= res_reg;
                    done <= 1'b1;
                end

                default: begin
                    // should not happen
                    mul_start <= 1'b0;
                    done      <= 1'b0;
                end
            endcase
        end
    end

    // Combinational next-state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start)
                    next_state = INIT;
            end

            INIT: begin
                next_state = BIT_CHECK;
            end

            BIT_CHECK: begin
                if (e_reg == 256'd0)
                    next_state = DONE;
                else if (e_reg[0] == 1'b1)
                    next_state = MUL_START;
                else
                    next_state = SQ_START;
            end

            MUL_START: begin
                if (mul_done)
                    next_state = SQ_START;
                else
                    next_state = MUL_WAIT;
            end

            MUL_WAIT: begin
                if (mul_done)
                    next_state = SQ_START;
                else
                    next_state = MUL_WAIT;
            end

            SQ_START: begin
                if (mul_done)
                    next_state = BIT_CHECK;
                else
                    next_state = SQ_WAIT;
            end

            SQ_WAIT: begin
                if (mul_done)
                    next_state = BIT_CHECK;
                else
                    next_state = SQ_WAIT;
            end

            DONE: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end
endmodule
