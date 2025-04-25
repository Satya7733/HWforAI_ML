// Generated automatically via PyRTL
// As one initial test of synthesis, map to FPGA with:
//   yosys -p "synth_xilinx -top toplevel" thisfile.v

module toplevel(clk, alpha, gamma, q_s2max, q_sa, reward, q_out);
    input clk;
    input[31:0] alpha;
    input[31:0] gamma;
    input[31:0] q_s2max;
    input[31:0] q_sa;
    input[31:0] reward;
    output[31:0] q_out;

    wire const_0_0;
    wire const_1_0;
    wire const_2_0;
    wire const_3_0;
    wire[63:0] tmp0;
    wire[31:0] tmp1;
    wire[63:0] tmp2;
    wire[64:0] tmp3;
    wire[32:0] tmp4;
    wire[64:0] tmp5;
    wire[65:0] tmp6;
    wire[33:0] tmp7;
    wire[65:0] tmp8;
    wire[131:0] tmp9;
    wire[99:0] tmp10;
    wire[131:0] tmp11;
    wire[132:0] tmp12;
    wire[31:0] tmp13;

    // Combinational
    assign const_0_0 = 0;
    assign const_1_0 = 0;
    assign const_2_0 = 0;
    assign const_3_0 = 0;
    assign q_out = tmp13;
    assign tmp0 = gamma * q_s2max;
    assign tmp1 = {const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0, const_0_0};
    assign tmp2 = {tmp1, reward};
    assign tmp3 = tmp2 + tmp0;
    assign tmp4 = {const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0, const_1_0};
    assign tmp5 = {tmp4, q_sa};
    assign tmp6 = tmp3 - tmp5;
    assign tmp7 = {const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0, const_2_0};
    assign tmp8 = {tmp7, alpha};
    assign tmp9 = tmp8 * tmp6;
    assign tmp10 = {const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0, const_3_0};
    assign tmp11 = {tmp10, q_sa};
    assign tmp12 = tmp11 + tmp9;
    assign tmp13 = {tmp12[31], tmp12[30], tmp12[29], tmp12[28], tmp12[27], tmp12[26], tmp12[25], tmp12[24], tmp12[23], tmp12[22], tmp12[21], tmp12[20], tmp12[19], tmp12[18], tmp12[17], tmp12[16], tmp12[15], tmp12[14], tmp12[13], tmp12[12], tmp12[11], tmp12[10], tmp12[9], tmp12[8], tmp12[7], tmp12[6], tmp12[5], tmp12[4], tmp12[3], tmp12[2], tmp12[1], tmp12[0]};

endmodule

