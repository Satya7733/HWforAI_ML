// File: tb/tb_point_add.v
// Testbench for point_add.v with all user‐specified cases, including doubling.

`timescale 1ns/1ps

module tb_point_add;
    reg           clk, rst_n;
    reg           start;
    reg  [255:0]  x1, y1;
    reg           inf1;
    reg  [255:0]  x2, y2;
    reg           inf2;

    wire [255:0]  x3, y3;
    wire          inf3, done;

    // Instantiate point_add
    point_add uut (
        .clk   (clk),
        .rst_n (rst_n),
        .start (start),
        .x1    (x1),
        .y1    (y1),
        .inf1  (inf1),
        .x2    (x2),
        .y2    (y2),
        .inf2  (inf2),
        .done  (done),
        .x3    (x3),
        .y3    (y3),
        .inf3  (inf3)
    );

    // Clock: 10 ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task check_add;
        input [255:0] A_x, A_y;
        input         A_inf;
        input [255:0] B_x, B_y;
        input         B_inf;
        input [255:0] Exp_x, Exp_y;
        input         Exp_inf;
        begin
            x1   = A_x;  y1   = A_y;  inf1 = A_inf;
            x2   = B_x;  y2   = B_y;  inf2 = B_inf;
            #10; start = 1'b1;
            #10; start = 1'b0;

            wait (done == 1'b1);
            #1;

            if (inf3 !== Exp_inf ||
                (inf3 == 1'b0 && (x3 !== Exp_x || y3 !== Exp_y))) begin
                $display("FAIL: Expected (%h,%h,inf=%b), Got (%h,%h,inf=%b)",
                         Exp_x, Exp_y, Exp_inf, x3, y3, inf3);
                $finish;
            end else begin
                $display("PASS");
            end
            #10;
        end
    endtask

    initial begin
        rst_n = 1'b0;
        start = 1'b0;
        x1    = 256'd0; y1 = 256'd0; inf1 = 1'b0;
        x2    = 256'd0; y2 = 256'd0; inf2 = 1'b0;
        #20;
        rst_n = 1'b1;
        #10;

        // ────────────────────────────────────────────────────────────────────
        // Additional Test Case A:
        //   x1 = 0xF7EFFD07C3B4B25E27EA5131778E98BA39FA9927F6AFAFE1D02B6F5C15AD2659
        //   y1 = 0x54847398406330788165B08893949F103EFEDC90ABF275FD19B0BD9E2F42EE18
        //   x2 = 0x6CCFAC186CA80303F04E32B73C9E103FB216FC09BAE5E52436BC17BEBED58820
        //   y2 = 0x860298E74916C903B6D342A505A2E2FB4B40B7463D94A6DD432E110C952B3B47
        // result:
        //   x  = 0x67A209D2F0DF6ADEC00DF71A621558CABE2312DFD1EBA167603C0D468DCB2B84
        //   y  = 0xF003EB8B57FA068CD93FE87B1D259F26230CEE8E106E3D080BE5F017B544452F
        check_add(
            256'hF7EFFD07C3B4B25E27EA5131778E98BA39FA9927F6AFAFE1D02B6F5C15AD2659,
            256'h54847398406330788165B08893949F103EFEDC90ABF275FD19B0BD9E2F42EE18,
            1'b0,
            256'h6CCFAC186CA80303F04E32B73C9E103FB216FC09BAE5E52436BC17BEBED58820,
            256'h860298E74916C903B6D342A505A2E2FB4B40B7463D94A6DD432E110C952B3B47,
            1'b0,
            256'h67A209D2F0DF6ADEC00DF71A621558CABE2312DFD1EBA167603C0D468DCB2B84,
            256'hF003EB8B57FA068CD93FE87B1D259F26230CEE8E106E3D080BE5F017B544452F,
            1'b0
        );

        // ────────────────────────────────────────────────────────────────────
        // Additional Test Case B (corrected expected result):
        //   x1 = 0x19A63E1715486C5699D292787F71E18BD91CDDB24F1AB84015276A2D0A5ABC97
        //   y1 = 0x834A8273FECFB5F1A5D02E820D3FF8B1B539659C716CAAF6A2BCFB452310C47
        //   x2 = 0xC38CD0C8168B102CFCC40DEB3B20D66723A75D7C6BF8C6B8BF5E199DBB90FC3B
        //   y2 = 0x697D8D9C7FB24AE1DE9F0FACEA07D1C6444789953FF366375835DE2F53EB4455
        // result:
        //   x  = 0xDE695A10943FC19584ECB7C98B85CC91116AA8821D57C6EC305A04B68A32D0D9
        //   y  = 0xE2B18FE5EB758C590BE479DEFBE4722771A29D62D1CD07256930F6C9BC7D5CB0
        check_add(
            256'h19A63E1715486C5699D292787F71E18BD91CDDB24F1AB84015276A2D0A5ABC97,
            256'h834A8273FECFB5F1A5D02E820D3FF8B1B539659C716CAAF6A2BCFB452310C47,
            1'b0,
            256'hC38CD0C8168B102CFCC40DEB3B20D66723A75D7C6BF8C6B8BF5E199DBB90FC3B,
            256'h697D8D9C7FB24AE1DE9F0FACEA07D1C6444789953FF366375835DE2F53EB4455,
            1'b0,
            256'hDE695A10943FC19584ECB7C98B85CC91116AA8821D57C6EC305A04B68A32D0D9,
            256'hE2B18FE5EB758C590BE479DEFBE4722771A29D62D1CD07256930F6C9BC7D5CB0,
            1'b0
        );

        // ────────────────────────────────────────────────────────────────────
        // Additional Test Case C:
        //   Point “result”:
        //     x = 0x1CAA72EAE8EAC3C9060EEA711056005597AB4C2DA1D20E03EC2278FBCF470F81
        //     y = 0x725081CB129A5C6375A82650D66B9F02975B0BFE2086E4025E51DD59D30E4F25
        //   “addend” Point:
        //     x = 0xBE0C4AC75AE82726AB9589CA86441295F2FBE340384950F43AC7E64FC3E0F376
        //     y = 0x916AD55AF2BC45369E78B3C3CADD0B285481DECF24EDC973DC0D020FE9E88CBB
        //   New result:
        //     x = 0x5422EABBBCC8BDBA888D6BF386CFF86BABE91466DD3787956980957258779195
        //     y = 0xA365795E83FFF4D5506AB241899144674223238900EB8790060746307300410B
        check_add(
            256'h1CAA72EAE8EAC3C9060EEA711056005597AB4C2DA1D20E03EC2278FBCF470F81,
            256'h725081CB129A5C6375A82650D66B9F02975B0BFE2086E4025E51DD59D30E4F25,
            1'b0,
            256'hBE0C4AC75AE82726AB9589CA86441295F2FBE340384950F43AC7E64FC3E0F376,
            256'h916AD55AF2BC45369E78B3C3CADD0B285481DECF24EDC973DC0D020FE9E88CBB,
            1'b0,
            256'h5422EABBBCC8BDBA888D6BF386CFF86BABE91466DD3787956980957258779195,
            256'hA365795E83FFF4D5506AB241899144674223238900EB8790060746307300410B,
            1'b0
        );

        // ────────────────────────────────────────────────────────────────────
        // Point Doubling Test:
        //   addend:
        //     x = 0x4A991F7C44E0C3796364193ADBB82DD47964B6431C79A9A3685CA2423C373ACF
        //     y = 0x605EECCB3BFDABDAFF7916274EFB8C992F8F52BCF1BA318BDDBB60915B94D755
        //   doubled addend:
        //     x = 0xF015694A1F7E48E1481CE48190CE72A8FF0CD85E3093274588EB8D46291222CC
        //     y = 0x2618750BD614F01D5787BD5CDD4392880F5D929404145EC80DFDA85C03481C8C
        check_add(
            256'h4A991F7C44E0C3796364193ADBB82DD47964B6431C79A9A3685CA2423C373ACF,
            256'h605EECCB3BFDABDAFF7916274EFB8C992F8F52BCF1BA318BDDBB60915B94D755,
            1'b0,
            256'h4A991F7C44E0C3796364193ADBB82DD47964B6431C79A9A3685CA2423C373ACF,
            256'h605EECCB3BFDABDAFF7916274EFB8C992F8F52BCF1BA318BDDBB60915B94D755,
            1'b0,
            256'hF015694A1F7E48E1481CE48190CE72A8FF0CD85E3093274588EB8D46291222CC,
            256'h2618750BD614F01D5787BD5CDD4392880F5D929404145EC80DFDA85C03481C8C,
            1'b0
        );

        $display("All point_add tests passed.");
        $finish;
    end
endmodule
