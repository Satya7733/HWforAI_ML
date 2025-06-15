`timescale 1ns/1ps
module scalar_mul_serial_top (
    input  wire clk,
    input  wire rst_n,
    // simple 32-bit serial bus
    input  wire wr_en,     // high for one cycle to write wr_data→register[addr]
    input  wire rd_en,     // high for one cycle to latch rd_data from register[addr]
    input  wire [4:0] addr,      // 0–7: k[31:0]…k[255:224], 8–15: Px, 16–23: Py, 24: Pinf, 25: start
    input  wire [31:0] wr_data,
    output reg  [31:0] rd_data,
    output reg rd_valid,  // high when rd_data is valid
    // scalar_mul interface handshake
    output wire done       // goes high one cycle when scalar_mul is finished
);


    // internal full-width registers
    reg  [255:0] k_reg, Px_reg, Py_reg;
    reg          Pinf_reg;
    reg          start_reg;

    // capture writes
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            k_reg     <= 256'd0;
            Px_reg    <= 256'd0;
            Py_reg    <= 256'd0;
            Pinf_reg  <= 1'b0;
            start_reg <= 1'b0;
        end else begin
            // de-assert start after one cycle
            if (start_reg)
                start_reg <= 1'b0;

            if (wr_en) begin
                case (addr)
                    // k
                    5'd0:  k_reg[ 31: 0] <= wr_data;
                    5'd1:  k_reg[ 63:32] <= wr_data;
                    5'd2:  k_reg[ 95:64] <= wr_data;
                    5'd3:  k_reg[127:96] <= wr_data;
                    5'd4:  k_reg[159:128]<= wr_data;
                    5'd5:  k_reg[191:160]<= wr_data;
                    5'd6:  k_reg[223:192]<= wr_data;
                    5'd7:  k_reg[255:224]<= wr_data;
                    // Px
                    5'd8:  Px_reg[ 31: 0] <= wr_data;
                    5'd9:  Px_reg[ 63:32] <= wr_data;
                    5'd10: Px_reg[ 95:64] <= wr_data;
                    5'd11: Px_reg[127:96] <= wr_data;
                    5'd12: Px_reg[159:128]<= wr_data;
                    5'd13: Px_reg[191:160]<= wr_data;
                    5'd14: Px_reg[223:192]<= wr_data;
                    5'd15: Px_reg[255:224]<= wr_data;
                    // Py
                    5'd16: Py_reg[ 31: 0] <= wr_data;
                    5'd17: Py_reg[ 63:32] <= wr_data;
                    5'd18: Py_reg[ 95:64] <= wr_data;
                    5'd19: Py_reg[127:96] <= wr_data;
                    5'd20: Py_reg[159:128]<= wr_data;
                    5'd21: Py_reg[191:160]<= wr_data;
                    5'd22: Py_reg[223:192]<= wr_data;
                    5'd23: Py_reg[255:224]<= wr_data;
                    // single-bit writes
                    5'd24: Pinf_reg  <= wr_data[0];
                    5'd25: start_reg <= wr_data[0];
                    default: ;
                endcase
            end
        end
    end

    // instantiate your scalar_mul core
    wire [255:0] Xout, Yout;
    wire         inf_out;
    scalar_mul u_scalar_mul (
        .clk    (clk),
        .rst_n  (rst_n),
        .start  (start_reg),
        .k      (k_reg),
        .Px     (Px_reg),
        .Py     (Py_reg),
        .Pinf   (Pinf_reg),
        .done   (done),
        .Xout   (Xout),
        .Yout   (Yout),
        .inf_out(inf_out)
    );

    // readback logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data  <= 32'd0;
            rd_valid <= 1'b0;
        end else begin
            rd_valid <= 1'b0;
            if (rd_en) begin
                rd_valid <= 1'b1;
                case (addr)
                    // read Xout words 0–7
                    5'd0:  rd_data <= Xout[ 31: 0];
                    5'd1:  rd_data <= Xout[ 63:32];
                    5'd2:  rd_data <= Xout[ 95:64];
                    5'd3:  rd_data <= Xout[127:96];
                    5'd4:  rd_data <= Xout[159:128];
                    5'd5:  rd_data <= Xout[191:160];
                    5'd6:  rd_data <= Xout[223:192];
                    5'd7:  rd_data <= Xout[255:224];
                    // read Yout words 8–15
                    5'd8:  rd_data <= Yout[ 31: 0];
                    5'd9:  rd_data <= Yout[ 63:32];
                    5'd10: rd_data <= Yout[ 95:64];
                    5'd11: rd_data <= Yout[127:96];
                    5'd12: rd_data <= Yout[159:128];
                    5'd13: rd_data <= Yout[191:160];
                    5'd14: rd_data <= Yout[223:192];
                    5'd15: rd_data <= Yout[255:224];
                    // read inf_out
                    5'd16: rd_data <= {31'd0, inf_out};
                    default: rd_data <= 32'd0;
                endcase
            end
        end
    end

endmodule
