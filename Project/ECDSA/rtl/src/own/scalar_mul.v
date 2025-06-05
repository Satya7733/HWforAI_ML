// File: src/scalar_mul.v
// ──────────────────────────────────────────────────────────────────────────
// Synthesizable Verilog for secp256k1 scalar‐multiplication using
// “double‐and‐add.”  Given a 256-bit scalar k and an input point P=(Px,Py),
// it computes R = k·P (affine) on secp256k1.  When `start`=1, it begins
// processing from the MSB of k; once all bits are done, it asserts `done`
// for one cycle and presents (Xout,Yout,inf_out).
// Debug $display statements have been added to trace execution.
// We have reordered BIT_LOOP so that “double currP” (E) comes before
// “R + currP” (C), preventing the infinite‐loop bug.
// ──────────────────────────────────────────────────────────────────────────

`timescale 1ns/1ps

module scalar_mul (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,       // 1‐cycle pulse to begin k·P
    input  wire [255:0] k,           // scalar multiplier
    input  wire [255:0] Px, Py,      // base point P
    input  wire         Pinf,        // 1 if P = ∞

    output reg          done,        // goes high for exactly 1 cycle when result ready
    output reg  [255:0] Xout, Yout,  // resulting point coordinates
    output reg         inf_out       // 1 if result = ∞
);

    // FSM states
    localparam [1:0]
        IDLE       = 2'd0,
        INIT       = 2'd1,
        BIT_LOOP   = 2'd2,
        DONE_STATE = 2'd3;

    reg [1:0] state, next_state;

    //--------------
    // “Working” registers
    //--------------
    reg [255:0] scalar_reg;
    reg [7:0]   bit_index;    // from 255 down to 0

    // “Accumulator” registers for R and “running” value for P
    // R starts at ∞; currP starts at input P.
    reg  [255:0] R_x, R_y;
    reg          R_inf;
    reg  [255:0] currP_x, currP_y;
    reg          currP_inf;

    // Signals to point_add
    reg           pa_start;
    reg  [255:0]  pa_x1, pa_y1;
    reg           pa_inf1;
    reg  [255:0]  pa_x2, pa_y2;
    reg           pa_inf2;

    wire          pa_done;
    wire [255:0]  pa_x3, pa_y3;
    wire          pa_inf3;

    // “flip‐flop” to detect rising edge of pa_done
    reg pa_done_prev;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pa_done_prev <= 1'b0;
        end else begin
            pa_done_prev <= pa_done;
        end
    end
    wire pa_done_rising = (pa_done && !pa_done_prev);

    //--------------
    // One‐bit “launch_flag” prevents pa_start from reasserting until the 
    // previous point_add has actually gone high and then low again. 
    //--------------
    reg launch_flag;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            launch_flag <= 1'b0;
        end else if (pa_done_prev && !pa_done) begin
            // Once pa_done finished its 1-cycle high, clear flag
            launch_flag <= 1'b0;
        end
    end

    // Instantiate point_add (assumes point_add.v is in the same folder)
    point_add u_point_add (
        .clk   (clk),
        .rst_n (rst_n),
        .start (pa_start),
        .x1    (pa_x1),
        .y1    (pa_y1),
        .inf1  (pa_inf1),
        .x2    (pa_x2),
        .y2    (pa_y2),
        .inf2  (pa_inf2),
        .done  (pa_done),
        .x3    (pa_x3),
        .y3    (pa_y3),
        .inf3  (pa_inf3)
    );

    //--------------
    // FSM sequential: state transitions
    //--------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    //--------------
    // FSM combinational: next_state logic
    //--------------
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start) next_state = INIT;
            end

            INIT: begin
                next_state = BIT_LOOP;
            end

            BIT_LOOP: begin
                // If final bit's doubling (of currP) finishes, go to DONE_STATE
                if (pa_done_rising && (bit_index == 8'd0)) begin
                    next_state = DONE_STATE;
                end else begin
                    next_state = BIT_LOOP;
                end
            end

            DONE_STATE: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    //--------------
    // Main datapath + control with $display debug
    //--------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done         <= 1'b0;
            scalar_reg   <= 256'd0;
            bit_index    <= 8'd0;
            R_x          <= 256'h0;
            R_y          <= 256'h0;
            R_inf        <= 1'b1;   // start with R = ∞
            currP_x      <= 256'h0;
            currP_y      <= 256'h0;
            currP_inf    <= 1'b1;   // will be overwritten in INIT
            pa_start     <= 1'b0;
            pa_x1        <= 256'h0;
            pa_y1        <= 256'h0;
            pa_inf1      <= 1'b0;
            pa_x2        <= 256'h0;
            pa_y2        <= 256'h0;
            pa_inf2      <= 1'b0;
            Xout         <= 256'h0;
            Yout         <= 256'h0;
            inf_out      <= 1'b1;
            launch_flag  <= 1'b0;
        end else begin
            // Default: do not re‐assert pa_start or done unless set below
            pa_start <= 1'b0;
            done     <= 1'b0;

            case (state)
                //--------------------------------------------
                IDLE: begin
                    // wait for start
                end

                //--------------------------------------------
                INIT: begin
                    // Latch inputs
                    scalar_reg <= k;
                    bit_index  <= 8'd255;
                    // R := ∞
                    R_inf   <= 1'b1;
                    R_x     <= 256'h0;
                    R_y     <= 256'h0;
                    // currP := input P
                    currP_x   <= Px;
                    currP_y   <= Py;
                    currP_inf <= Pinf;
                    launch_flag <= 1'b0;
                    $display("INIT: k=%h, P=(%h,%h,inf=%b)", k, Px, Py, Pinf);
                end

                //--------------------------------------------
                BIT_LOOP: begin
                    // — (D) If pa_done has fallen, double currP & decrement bit_index
                    if (pa_done_prev && !pa_done) begin
                        pa_x1      <= currP_x;
                        pa_y1      <= currP_y;
                        pa_inf1    <= currP_inf;
                        pa_x2      <= currP_x;
                        pa_y2      <= currP_y;
                        pa_inf2    <= currP_inf;
                        pa_start   <= 1'b1;
                        launch_flag<= 1'b1;
                        $display("BIT_LOOP[%0d]: Doubling currP=(%h,%h,inf=%b)",
                                 bit_index, currP_x, currP_y, currP_inf);
                    end

                    // — (A) If no operation in flight, start doubling R
                    else if (!launch_flag) begin
                        pa_x1      <= R_x;
                        pa_y1      <= R_y;
                        pa_inf1    <= R_inf;
                        pa_x2      <= R_x;
                        pa_y2      <= R_y;
                        pa_inf2    <= R_inf;
                        pa_start   <= 1'b1;
                        launch_flag<= 1'b1;
                        $display("BIT_LOOP[%0d]: Doubling R=(%h,%h,inf=%b)",
                                 bit_index, R_x, R_y, R_inf);
                    end

                    // — (B) When doubling R finishes (R + R):
                    else if (pa_done_rising && (pa_x2 == R_x && pa_inf2 == R_inf) ) begin
                        R_x   <= pa_x3;
                        R_y   <= pa_y3;
                        R_inf <= pa_inf3;
                        $display("DOUBLE_R_DONE[%0d]: R<= (%h,%h,inf=%b)",
                                 bit_index, pa_x3, pa_y3, pa_inf3);

                        // If this bit is 1, do R := R + currP
                        if (scalar_reg[bit_index] == 1'b1) begin
                            pa_x1      <= pa_x3;    // new R
                            pa_y1      <= pa_y3;
                            pa_inf1    <= pa_inf3;
                            pa_x2      <= currP_x;
                            pa_y2      <= currP_y;
                            pa_inf2    <= currP_inf;
                            pa_start   <= 1'b1;
                            launch_flag<= 1'b1;
                            $display("BIT_LOOP[%0d]: Adding currP=(%h,%h,inf=%b) to R=(%h,%h,inf=%b)",
                                     bit_index, currP_x, currP_y, currP_inf,
                                     pa_x3, pa_y3, pa_inf3);
                        end else begin
                            launch_flag<= 1'b0;
                        end
                    end

                    // — (E) When “doubling currP” finishes:
                    else if (pa_done_rising &&
                             pa_x1 == currP_x && pa_inf1 == currP_inf &&
                             pa_x2 == currP_x && pa_inf2 == currP_inf) begin
                        currP_x   <= pa_x3;
                        currP_y   <= pa_y3;
                        currP_inf <= pa_inf3;
                        $display("DOUBLE_P_DONE[%0d]: currP<= (%h,%h,inf=%b)",
                                 bit_index, pa_x3, pa_y3, pa_inf3);
                        if (bit_index != 8'd0) begin
                            bit_index <= bit_index - 8'd1;
                            $display("BIT_LOOP: Next bit_index = %0d", bit_index - 8'd1);
                        end
                        launch_flag <= 1'b0;
                    end

                    // — (C) When “R + currP” finishes:
                    else if (pa_done_rising &&
                             pa_x2 == currP_x && pa_inf2 == currP_inf) begin
                        R_x   <= pa_x3;
                        R_y   <= pa_y3;
                        R_inf <= pa_inf3;
                        $display("ADD_DONE[%0d]: R<= (%h,%h,inf=%b)",
                                 bit_index, pa_x3, pa_y3, pa_inf3);
                        launch_flag <= 1'b0;
                    end

                    // Otherwise, idle until one of the above triggers
                end

                //--------------------------------------------
                DONE_STATE: begin
                    Xout    <= R_x;
                    Yout    <= R_y;
                    inf_out <= R_inf;
                    done    <= 1'b1;
                    $display("DONE_STATE: Final R = (%h,%h,inf=%b)",
                             R_x, R_y, R_inf);
                end

                //--------------------------------------------
                default: begin
                    // no‐op
                end
            endcase
        end
    end
endmodule
