`timescale 1ns/1ps

// Prime constant for secp256k1
`define P 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
// Curve parameter a=0
`define A 256'h0

//-----------------------------------------------------------------------------
// inv_mod: multi-cycle modular inverse (k^(m-2) mod m)
//-----------------------------------------------------------------------------
module inv_mod(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [255:0] k,
    input  wire [255:0] m,
    output reg  [255:0] inv,
    output reg          valid
);
    reg [1:0] state;
    localparam S_IDLE = 2'd0, S_CALC = 2'd1, S_DONE = 2'd2;
    reg [255:0] base_reg, exp_reg, mod_reg, result_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            base_reg   <= 0;
            exp_reg    <= 0;
            mod_reg    <= 0;
            result_reg <= 0;
            inv        <= 0;
            valid      <= 0;
        end else case (state)
            S_IDLE: begin
                base_reg   <= k % m;
                exp_reg    <= m - 2;
                mod_reg    <= m;
                result_reg <= 1;
                valid      <= 0;
                state      <= S_CALC;
            end
            S_CALC: begin
                if (exp_reg != 0) begin
                    if (exp_reg[0])
                        result_reg <= (result_reg * base_reg) % mod_reg;
                    base_reg <= (base_reg * base_reg) % mod_reg;
                    exp_reg  <= exp_reg >> 1;
                end else begin
                    inv   <= result_reg;
                    valid <= 1;
                    state <= S_DONE;
                end
            end
            S_DONE: begin
                state <= S_DONE;
            end
        endcase
    end
endmodule

//-----------------------------------------------------------------------------
// point_add: combinational EC point addition over F_p
//-----------------------------------------------------------------------------
module point_add(
    input  wire [255:0] x1, y1,
    input  wire [255:0] x2, y2,
    output reg  [255:0] x3, y3
);
    reg [255:0] num, den, lambda;

    // modular inverse via Fermat's little theorem function
    function [255:0] inv_mod_f;
        input [255:0] x;
        input [255:0] mod;
        integer i;
        reg [255:0] res, b, exp;
        begin
            res = 1;
            b   = x % mod;
            exp = mod - 2;
            for (i = 0; i < 256; i = i + 1) begin
                if (exp[i])
                    res = (res * b) % mod;
                b = (b * b) % mod;
            end
            inv_mod_f = res;
        end
    endfunction

    always @* begin
        if (x1==0 && y1==0) begin
            x3 = x2; y3 = y2;
        end else if (x2==0 && y2==0) begin
            x3 = x1; y3 = y1;
        end else if ((x1==x2) && ((y1+y2) % `P == 0)) begin
            x3 = 0;  y3 = 0;
        end else begin
            num    = (y2 + `P - y1) % `P;
            den    = (x2 + `P - x1) % `P;
            lambda = (num * inv_mod_f(den, `P)) % `P;
            x3     = (lambda*lambda + `P - x1 + `P - x2) % `P;
            y3     = (lambda*(x1 + `P - x3) + `P - y1) % `P;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// point_double: combinational EC point doubling over F_p
//-----------------------------------------------------------------------------
module point_double(
    input  wire [255:0] x1, y1,
    output reg  [255:0] x3, y3
);
    reg [255:0] num, den, lambda;

    function [255:0] inv_mod_f;
        input [255:0] x;
        input [255:0] mod;
        integer i;
        reg [255:0] res, b, exp;
        begin
            res = 1;
            b   = x % mod;
            exp = mod - 2;
            for (i = 0; i < 256; i = i + 1) begin
                if (exp[i])
                    res = (res * b) % mod;
                b = (b * b) % mod;
            end
            inv_mod_f = res;
        end
    endfunction

    always @* begin
        if (x1==0 && y1==0) begin
            x3 = 0; y3 = 0;
        end else begin
            num    = (3 * x1 * x1 + `A) % `P;
            den    = (2 * y1) % `P;
            lambda = (num * inv_mod_f(den, `P)) % `P;
            x3 = (lambda*lambda + `P - 2*x1) % `P;
            y3 = (lambda*(x1 + `P - x3) + `P - y1) % `P;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// scalar_mult: multi-cycle double-and-add
//-----------------------------------------------------------------------------
module scalar_mult(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [255:0] k,
    input  wire [255:0] Px, Py,
    output reg  [255:0] Rx, Ry,
    output reg          valid
);
    reg [1:0] state;
    localparam S_IDLE = 2'd0, S_CALC = 2'd1, S_DONE = 2'd2;
    reg [255:0] k_reg, Ax, Ay, Rx_reg, Ry_reg;
    reg [8:0]  bit_cnt;
    wire [255:0] pa_x, pa_y, pd_x, pd_y;

    point_add    PA(.x1(Rx_reg), .y1(Ry_reg), .x2(Ax), .y2(Ay), .x3(pa_x), .y3(pa_y));
    point_double PD(.x1(Ax),       .y1(Ay),       .x3(pd_x), .y3(pd_y));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= S_IDLE;
            k_reg   <= 0; Ax <= 0; Ay <= 0;
            Rx_reg <= 0; Ry_reg <= 0; bit_cnt <= 9'd0;
            Rx <= 0; Ry <= 0; valid <= 0;
        end else case (state)
            S_IDLE: begin
                k_reg   <= k;
                Ax      <= Px; Ay <= Py;
                Rx_reg  <= 0; Ry_reg <= 0;
                bit_cnt <= 9'd0;
                valid   <= 0;
                state   <= S_CALC;
            end
            S_CALC: begin
                if (bit_cnt < 9'd256) begin
                    if (k_reg[0]) begin
                        Rx_reg <= pa_x;
                        Ry_reg <= pa_y;
                    end
                    Ax      <= pd_x;
                    Ay      <= pd_y;
                    k_reg   <= k_reg >> 1;
                    bit_cnt <= bit_cnt + 1;
                end else begin
                    Rx    <= Rx_reg;
                    Ry    <= Ry_reg;
                    valid <= 1;
                    state <= S_DONE;
                end
            end
            S_DONE: begin
                state <= S_DONE;
            end
        endcase
    end
endmodule
