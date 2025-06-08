`timescale 1ns/1ps

module scalar_mul (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [255:0] k,
    input  wire [255:0] Px, Py,
    input  wire         Pinf,

    output reg          done,
    output reg  [255:0] Xout, Yout,
    output reg         inf_out
);

    // top FSM states
    localparam [1:0]
        IDLE       = 2'd0,
        INIT       = 2'd1,
        BIT_LOOP   = 2'd2,
        DONE_STATE = 2'd3;

    // micro-FSM states inside BIT_LOOP
    localparam [2:0]
        A_IDLE      = 3'd0,
        A_ADD_START = 3'd1,
        A_ADD_WAIT  = 3'd2,
        A_DBL_START = 3'd3,
        A_DBL_WAIT  = 3'd4;

    reg [1:0]  state, next_state;
    reg [2:0]  astate;

    // Working registers
    reg [255:0] scalar_reg;
    reg [7:0]   bit_index;

    // Accumulators
    reg  [255:0] R_x, R_y;
    reg          R_inf;
    reg  [255:0] currP_x, currP_y;
    reg          currP_inf;

    // point_add interface
    reg           pa_start;
    reg  [255:0]  pa_x1, pa_y1;
    reg           pa_inf1;
    reg  [255:0]  pa_x2, pa_y2;
    reg           pa_inf2;
    wire          pa_done;
    wire [255:0]  pa_x3, pa_y3;
    wire          pa_inf3;

    // edge-detect
    reg pa_done_prev;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) pa_done_prev <= 1'b0;
        else         pa_done_prev <= pa_done;
    end
    wire pa_done_rising = pa_done && !pa_done_prev;

    // point_add instance
    point_add u_point_add (
        .clk   (clk),   .rst_n (rst_n),
        .start (pa_start),
        .x1    (pa_x1), .y1 (pa_y1), .inf1(pa_inf1),
        .x2    (pa_x2), .y2 (pa_y2), .inf2(pa_inf2),
        .done  (pa_done),
        .x3    (pa_x3), .y3 (pa_y3), .inf3(pa_inf3)
    );

    // top-level FSM sequential
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            done        <= 1'b0;
            scalar_reg  <= 256'd0;
            bit_index   <= 8'd0;
            R_x         <= 256'h0;  R_y <= 256'h0; R_inf  <= 1'b1;
            currP_x     <= 256'h0;  currP_y <= 256'h0; currP_inf <= 1'b1;
            pa_start    <= 1'b0;
            pa_x1       <= 256'h0;  pa_y1 <= 256'h0;  pa_inf1 <= 1'b0;
            pa_x2       <= 256'h0;  pa_y2 <= 256'h0;  pa_inf2 <= 1'b0;
            Xout        <= 256'h0;  Yout <= 256'h0;   inf_out <= 1'b1;
            astate      <= A_IDLE;
        end else begin
            state <= next_state;
            // clear add start each cycle
            pa_start <= 1'b0;
            done     <= 1'b0;

            case (state)
            //--------------------------------------------
            IDLE: begin
                // nothing until start
            end

            //--------------------------------------------
            INIT: begin
                scalar_reg <= k;
                bit_index  <= 8'd255;
                R_inf      <= 1'b1;
                R_x        <= 256'h0;  R_y <= 256'h0;
                currP_x    <= Px;       currP_y <= Py;
                currP_inf  <= Pinf;
                astate     <= A_IDLE;

                $display("\n**** New scalar_mult ****");
                $display("Scalar k = %h", k);
                $display("Point P = (%h, %h, inf=%b)", Px, Py, Pinf);
            end

            //--------------------------------------------
            BIT_LOOP: begin
                // micro-FSM for “if LSB then add R+=P; always double P; shift k”
                case (astate)
                //------------------------------------------------
                A_IDLE: begin
                    if (scalar_reg[0]) begin
                        // R = R + P
                        pa_x1    <= R_x;      pa_y1 <= R_y;      pa_inf1 <= R_inf;
                        pa_x2    <= currP_x;  pa_y2 <= currP_y;  pa_inf2 <= currP_inf;
                        pa_start <= 1'b1;
                        astate   <= A_ADD_WAIT;
                       // $display("\n[ADD_START] bit %0d: R += P", bit_index);
                    end else begin
                        astate <= A_DBL_START;
                    end
                end

                //------------------------------------------------
                A_ADD_WAIT: begin
                    if (pa_done_rising) begin
                        R_x   <= pa_x3;  R_y   <= pa_y3;  R_inf <= pa_inf3;
                        astate <= A_DBL_START;
                      //  $display("[ADD_DONE] -> R = (%h, %h, inf=%b)", pa_x3, pa_y3, pa_inf3);
                    end
                end

                //------------------------------------------------
                A_DBL_START: begin
                    // P = 2 * P
                    pa_x1    <= currP_x;  pa_y1 <= currP_y;  pa_inf1 <= currP_inf;
                    pa_x2    <= currP_x;  pa_y2 <= currP_y;  pa_inf2 <= currP_inf;
                    pa_start <= 1'b1;
                    astate   <= A_DBL_WAIT;
                  //  $display("\n[DBL_START] bit %0d: P = 2*P", bit_index);
                end

                //------------------------------------------------
                A_DBL_WAIT: begin
                    if (pa_done_rising) begin
                        currP_x     <= pa_x3;
                        currP_y     <= pa_y3;
                        currP_inf   <= pa_inf3;
                        scalar_reg  <= scalar_reg >> 1;
                        bit_index   <= bit_index - 1;
                        astate      <= A_IDLE;
                      //  $display("[DBL_DONE] -> P = (%h, %h, inf=%b)", pa_x3, pa_y3, pa_inf3);
                    end
                end

                default: astate <= A_IDLE;
                endcase
            end

            //--------------------------------------------
            DONE_STATE: begin
                Xout    <= R_x;
                Yout    <= R_y;
                inf_out <= R_inf;
                done    <= 1'b1;
                $display("\n=== Final Output k*P ===");
                $display("  x = %h", R_x);
                $display("  y = %h", R_y);
            end

            default: ;
            endcase
        end
    end

    // top-level FSM next-state
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:       if (start)                         next_state = INIT;
            INIT:                                         next_state = BIT_LOOP;
            BIT_LOOP:  if (pa_done_rising && bit_index==0) next_state = DONE_STATE;
            DONE_STATE:                                   next_state = IDLE;
            default:                                      next_state = IDLE;
        endcase
    end

endmodule
