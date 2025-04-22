module q_update_core (
    input  logic         clk,
    input  logic         rst,
    input  logic         start,
    input  logic signed [15:0] Q_current,
    input  logic signed [15:0] Q_next_0,
    input  logic signed [15:0] Q_next_1,
    input  logic signed [15:0] Q_next_2,
    input  logic signed [15:0] Q_next_3,
    input  logic signed [15:0] reward,
    input  logic signed [15:0] alpha,
    input  logic signed [15:0] gamma,
    output logic signed [15:0] Q_new,
    output logic         done
);

    typedef enum logic [1:0] {
        IDLE,
        FIND_MAX,
        COMPUTE,
        DONE
    } state_t;

    state_t state, next_state;

    logic signed [15:0] max_q_next;
    logic signed [31:0] temp1, temp2, temp3, temp4, temp5;
    logic signed [31:0] one_minus_alpha;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE:       if (start) next_state = FIND_MAX;
            FIND_MAX:   next_state = COMPUTE;
            COMPUTE:    next_state = DONE;
            DONE:       next_state = IDLE;
        endcase
    end

    // Max Q[s', a']
    always_ff @(posedge clk) begin
        if (state == FIND_MAX) begin
            max_q_next <= Q_next_0;
            if (Q_next_1 > max_q_next) max_q_next <= Q_next_1;
            if (Q_next_2 > max_q_next) max_q_next <= Q_next_2;
            if (Q_next_3 > max_q_next) max_q_next <= Q_next_3;
        end
    end

    // Q-update computation (Q4.12 fixed point)
    always_ff @(posedge clk) begin
        if (state == COMPUTE) begin
            one_minus_alpha <= (16'h1000 - alpha);  // 1.0 in Q4.12 = 0x1000
            temp1 <= (gamma * max_q_next) >>> 12;    // γ * max_Q_next
            temp2 <= reward + temp1[15:0];           // reward + γ * max_Q_next
            temp3 <= (alpha * temp2[15:0]) >>> 12;   // α * (reward + γ * max_Q_next)
            temp4 <= (one_minus_alpha * Q_current) >>> 12; // (1-α) * Q_current
            temp5 <= temp3 + temp4;                 // final Q_new
        end
    end

    // Output & done flag
    always_ff @(posedge clk) begin
        if (state == DONE) begin
            Q_new <= temp5[15:0];
        end
    end

    assign done = (state == DONE);

endmodule
