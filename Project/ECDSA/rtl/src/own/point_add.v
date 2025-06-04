// File: src/point_add.v
// ──────────────────────────────────────────────────────────────────────────
// Synthesizable Verilog for secp256k1 affine point‐addition (x₃, y₃).
// Uses the corrected mod_sub above so that all “A–B” operations reduce mod p.
// ──────────────────────────────────────────────────────────────────────────

module point_add (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,    // pulse to begin P + Q
    input  wire [255:0] x1,
    input  wire [255:0] y1,
    input  wire         inf1,     // 1 if P = ∞
    input  wire [255:0] x2,
    input  wire [255:0] y2,
    input  wire         inf2,     // 1 if Q = ∞

    output reg          done,     // one cycle when (x3,y3,inf3) valid
    output reg  [255:0] x3,
    output reg  [255:0] y3,
    output reg         inf3      // 1 if result = ∞
);
    // secp256k1 prime
    localparam [255:0] P_CONST =
        256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    // FSM states
    localparam [4:0]
        IDLE         = 5'd0,
        CHECK_INF    = 5'd1,
        CHECK_NEG    = 5'd2,
        PREP_CALC    = 5'd3,
        WAIT_X1SQ    = 5'd4,
        CALC_DBL     = 5'd5,   // double path: compute 3*x1^2,2*y1 → inv
        START_INV    = 5'd6,   // addition path: invoke inv here
        WAIT_INV     = 5'd7,
        START_LAM    = 5'd8,
        WAIT_LAM     = 5'd9,
        START_LAM_SQ = 5'd10,
        WAIT_LAM_SQ  = 5'd11,
        CALC_X3      = 5'd12,  // x3 = λ² - (x1 + x2)
        START_Y      = 5'd13,
        WAIT_Y       = 5'd14,
        CALC_Y       = 5'd15,  // y3 = λ*(x1 - x3) - y1
        DONE_STATE   = 5'd16;

    reg [4:0] state, next_state;

    // Latched inputs
    reg [255:0] lx1, ly1, lx2, ly2;
    reg         linf1, linf2;

    // Flags
    reg         is_double;
    reg         is_neg;

    // Numerator/denominator for λ
    reg  [255:0] num, den;

    // λ, λ², λ*(x1 - x3)
    reg  [255:0] lam;
    reg  [255:0] lam_sq;
    reg  [255:0] mult_lam_x1_x3;

    // Registered x1²
    reg  [255:0] x1_sq_reg;

    // Control signals for mod_mul and mod_inv
    reg             mul_start;
    reg  [255:0]    mul_a, mul_b;
    wire [255:0]    mul_r;
    wire            mul_done;

    reg             inv_start;
    wire [255:0]    den_inv;
    wire            inv_done;

    // Wires for modular additions/subtractions
    wire [255:0] sub_y2_y1;       // (y2 - y1) mod p
    wire [255:0] sub_x2_x1;       // (x2 - x1) mod p
    wire [255:0] two_y1;          // 2*y1
    wire [255:0] add_x1_x2;       // x1 + x2
    wire [255:0] sub_lam_sq_x1x2; // λ² - (x1 + x2)
    wire [255:0] sub_x1_x3;       // x1 - x3
    wire [255:0] sub_mult_y1;     // λ*(x1 - x3) - y1

    // Wires for doubling: 2*x1², 3*x1² (from x1_sq_reg)
    wire [255:0] two_x1_sq;
    wire [255:0] three_x1_sq;

    // Instantiate modular subtractions and additions:
    // Each mod_sub does (A - B) mod p, using the corrected code above.
    mod_sub u_sub_y2_y1 (
        .A(lx2), .B(ly1), .R(sub_y2_y1)
    );
    mod_sub u_sub_x2_x1 (
        .A(lx2), .B(lx1), .R(sub_x2_x1)
    );
    mod_add u_add_y1_y1 (
        .A(ly1), .B(ly1), .R(two_y1)
    );
    mod_add u_add_x1_x2 (
        .A(lx1), .B(lx2), .R(add_x1_x2)
    );
    mod_sub u_sub_lam_sq_x1x2 (
        .A(lam_sq), .B(add_x1_x2), .R(sub_lam_sq_x1x2)
    );
    mod_sub u_sub_x1_x3 (
        .A(lx1), .B(x3), .R(sub_x1_x3)
    );
    mod_sub u_sub_mult_y1 (
        .A(mult_lam_x1_x3), .B(ly1), .R(sub_mult_y1)
    );

    // Doubling helpers: 2*x1_sq_reg, 3*x1_sq_reg
    mod_add u_add_x1sq_x1sq (
        .A(x1_sq_reg), .B(x1_sq_reg), .R(two_x1_sq)
    );
    mod_add u_add_two_x1sq_x1sq (
        .A(two_x1_sq), .B(x1_sq_reg), .R(three_x1_sq)
    );

    // Single mod_mul instance (shared)
    mod_mul u_mod_mul (
        .clk   (clk),
        .rst_n (rst_n),
        .start (mul_start),
        .A     (mul_a),
        .B     (mul_b),
        .R     (mul_r),
        .done  (mul_done)
    );

    // Single mod_inv instance (shared)
    mod_inv u_mod_inv (
        .clk   (clk),
        .rst_n (rst_n),
        .start (inv_start),
        .A     (den),
        .R     (den_inv),
        .done  (inv_done)
    );

    // ────────────────────────────────────────────────────────────────────────
    // FSM + register updates (with debug $display):
    // ────────────────────────────────────────────────────────────────────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= IDLE;
            lx1             <= 256'd0;  ly1 <= 256'd0;
            lx2             <= 256'd0;  ly2 <= 256'd0;
            linf1           <= 1'b0;    linf2 <= 1'b0;
            is_double       <= 1'b0;    is_neg <= 1'b0;
            num             <= 256'd0;  den <= 256'd0;
            lam             <= 256'd0;  lam_sq <= 256'd0;
            mult_lam_x1_x3  <= 256'd0;
            x1_sq_reg       <= 256'd0;
            x3              <= 256'd0;  y3 <= 256'd0;
            inf3            <= 1'b0;    done <= 1'b0;
            mul_start       <= 1'b0;    mul_a <= 256'd0;
            mul_b           <= 256'd0;  inv_start <= 1'b0;
        end else begin
            state <= next_state;
            // Default: deassert these each cycle
            done      <= 1'b0;
            mul_start <= 1'b0;
            inv_start <= 1'b0;

            case (state)
                IDLE: begin
                    if (start) begin
                        lx1   <= x1;   ly1 <= y1;
                        lx2   <= x2;   ly2 <= y2;
                        linf1 <= inf1; linf2 <= inf2;
                        $display("IDLE->CHECK_INF: P=(%h,%h), Q=(%h,%h), inf1=%b, inf2=%b",
                                  x1, y1, x2, y2, inf1, inf2);
                    end
                end

                CHECK_INF: begin
                    $display("CHECK_INF->CHECK_NEG");
                end

                CHECK_NEG: begin
                    is_double <= (!linf1 && !linf2 && (lx1 == lx2) && (ly1 == ly2));
                    is_neg    <= (!linf1 && !linf2 && (lx1 == lx2) &&
                                 ((ly1 + ly2) == P_CONST));
                    $display("CHECK_NEG: is_double=%b, is_neg=%b", is_double, is_neg);
                end

                PREP_CALC: begin
                    $display("PREP_CALC: linf1=%b, linf2=%b, is_neg=%b, is_double=%b",
                              linf1, linf2, is_neg, is_double);
                    if (linf1) begin
                        x3   <= lx2;  y3 <= ly2;
                        inf3 <= linf2;
                        done <= 1'b1;
                        $display("PREP_CALC: P is ∞ → R=Q=(%h,%h)", lx2, ly2);
                    end else if (linf2) begin
                        x3   <= lx1;  y3 <= ly1;
                        inf3 <= linf1;
                        done <= 1'b1;
                        $display("PREP_CALC: Q is ∞ → R=P=(%h,%h)", lx1, ly1);
                    end else if (is_neg) begin
                        inf3 <= 1'b1;
                        done <= 1'b1;
                        $display("PREP_CALC: P + (−P) → ∞");
                    end else begin
                        inf3 <= 1'b0;
                        if (is_double) begin
                            // Doubling path: compute x1²
                            mul_start <= 1'b1;
                            mul_a     <= lx1;
                            mul_b     <= lx1;
                            $display("PREP_CALC: Doubling → start mul x1*x1 = %h * %h",
                                      lx1, lx1);
                        end else begin
                            // Addition path: num = (y2 - y1) mod p, den = (x2 - x1) mod p
                            num <= sub_y2_y1;
                            den <= sub_x2_x1;
                            $display("PREP_CALC: Addition → num=y2-y1=%h, den=x2-x1=%h",
                                      sub_y2_y1, sub_x2_x1);
                        end
                    end
                end

                WAIT_X1SQ: begin
                    if (mul_done) begin
                        x1_sq_reg <= mul_r;  // x1²
                        $display("WAIT_X1SQ: mul_done, x1_sq=%h", mul_r);
                        $display("WAIT_X1SQ: (two_x1_sq next)=%h, (three_x1_sq next)=%h, two_y1=%h",
                                  two_x1_sq, three_x1_sq, two_y1);
                    end
                end

                CALC_DBL: begin
                    // Doubling: num=3*x1², den=2*y1 → inv
                    num       <= three_x1_sq;
                    den       <= two_y1;
                    inv_start <= 1'b1;
                    $display("CALC_DBL: num=3*x1^2=%h, den=2*y1=%h; start mod_inv",
                              three_x1_sq, two_y1);
                end

                START_INV: begin
                    if (!is_double) begin
                        // Addition path: assert inv_start now
                        inv_start <= 1'b1;
                        $display("START_INV (addition): num=%h, den=%h; asserting inv_start",
                                  num, den);
                    end else begin
                        // Doubling path: inv_start was asserted in CALC_DBL
                        $display("START_INV (doubling): waiting for inv_done");
                    end
                end

                WAIT_INV: begin
                    if (inv_done) begin
                        $display("WAIT_INV: inv_done, den_inv=%h", den_inv);
                    end
                end

                START_LAM: begin
                    mul_start <= 1'b1;
                    mul_a     <= num;
                    mul_b     <= den_inv;
                    $display("START_LAM: start mul num*den_inv = %h * %h", num, den_inv);
                end

                WAIT_LAM: begin
                    if (mul_done) begin
                        lam <= mul_r;
                        $display("WAIT_LAM: mul_done, lam=%h", mul_r);
                    end
                end

                START_LAM_SQ: begin
                    mul_start <= 1'b1;
                    mul_a     <= lam;
                    mul_b     <= lam;
                    $display("START_LAM_SQ: start mul lam*lam = %h * %h", lam, lam);
                end

                WAIT_LAM_SQ: begin
                    if (mul_done) begin
                        lam_sq <= mul_r;
                        $display("WAIT_LAM_SQ: mul_done, lam_sq=%h", mul_r);
                        $display("WAIT_LAM_SQ: add_x1_x2=%h", add_x1_x2);
                    end
                end

                CALC_X3: begin
                    // x3 = lam_sq - (x1 + x2)
                    x3 <= sub_lam_sq_x1x2;
                    $display("CALC_X3: x3 = lam_sq - (x1 + x2) = %h", sub_lam_sq_x1x2);
                end

                START_Y: begin
                    mul_start <= 1'b1;
                    mul_a     <= lam;
                    mul_b     <= sub_x1_x3;
                    $display("START_Y: start mul lam*(x1-x3) = %h * %h", lam, sub_x1_x3);
                end

                WAIT_Y: begin
                    if (mul_done) begin
                        mult_lam_x1_x3 <= mul_r;
                        $display("WAIT_Y: mul_done, lam*(x1-x3)=%h", mul_r);
                    end
                end

                CALC_Y: begin
                    // y3 = lam*(x1-x3) - y1
                    y3   <= sub_mult_y1;
                    done <= 1'b1;
                    inf3 <= 1'b0;
                    $display("CALC_Y: lam*(x1-x3)=%h, y3=%h",
                              mult_lam_x1_x3, sub_mult_y1);
                end

                DONE_STATE: begin
                    $display("DONE_STATE: x3=%h, y3=%h, inf3=%b", x3, y3, inf3);
                end

                default: begin
                    // no‐op
                end
            endcase
        end
    end

    // ────────────────────────────────────────────────────────────────────────
    // Next‐state combinational logic:
    // ────────────────────────────────────────────────────────────────────────
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:         if (start)            next_state = CHECK_INF;
            CHECK_INF:                            next_state = CHECK_NEG;
            CHECK_NEG:                            next_state = PREP_CALC;
            PREP_CALC:   if (linf1||linf2||is_neg) next_state = DONE_STATE;
                         else if (is_double)      next_state = WAIT_X1SQ;
                         else                     next_state = START_INV;

            WAIT_X1SQ:   if (mul_done)          next_state = CALC_DBL;
            CALC_DBL:                          next_state = START_INV;
            START_INV:                         next_state = WAIT_INV;
            WAIT_INV:   if (inv_done)           next_state = START_LAM;
            START_LAM:                         next_state = WAIT_LAM;
            WAIT_LAM:   if (mul_done)          next_state = START_LAM_SQ;
            START_LAM_SQ:                      next_state = WAIT_LAM_SQ;
            WAIT_LAM_SQ: if (mul_done)          next_state = CALC_X3;
            CALC_X3:                           next_state = START_Y;
            START_Y:                           next_state = WAIT_Y;
            WAIT_Y:    if (mul_done)           next_state = CALC_Y;
            CALC_Y:                            next_state = DONE_STATE;
            DONE_STATE:                        next_state = IDLE;
            default:                           next_state = IDLE;
        endcase
    end
endmodule
