`timescale 1ns/1ps

module tb_tf_pe;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic clear = 1'b0;
    logic hold = 1'b0;
    logic int4_mode = 1'b0;
    logic signed [7:0] a_in, b_in, a_out, b_out;
    logic [1:0] valid_in, valid_out;
    logic signed [31:0] acc_out;

    logic signed [7:0] expected_a_out, expected_b_out;
    logic [1:0] expected_valid_out;

    tf_pe dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .hold(hold),
        .int4_mode(int4_mode),
        .a_in(a_in),
        .b_in(b_in),
        .a_valid_in(valid_in[1]),
        .b_valid_in(valid_in[0]),
        .a_out(a_out),
        .b_out(b_out),
        .a_valid_out(valid_out[1]),
        .b_valid_out(valid_out[0]),
        .acc_out(acc_out)
    );

    always #5 clk = ~clk;

    task automatic step(
        input string label,
        input logic signed [7:0] a,
        input logic signed [7:0] b,
        input logic signed [31:0] expected_acc,
        input logic [1:0] valid = 2'b11
    );
        @(negedge clk);
        a_in = a;
        b_in = b;
        valid_in = valid;

        if (!rst_n) begin
            expected_a_out = '0;
            expected_b_out = '0;
            expected_valid_out = '0;
        end else if (!hold) begin
            expected_a_out = a;
            expected_b_out = b;
            expected_valid_out = valid;
        end

        @(posedge clk);
        #1;
        if (acc_out !== expected_acc)
            $fatal(1, "%s: accumulator expected %0d, got %0d", label, expected_acc, acc_out);
        if ({a_out, b_out, valid_out} !== {expected_a_out, expected_b_out, expected_valid_out})
            $fatal(1, "%s: forwarded A=%h B=%h valid=%b, expected A=%h B=%h valid=%b",
                   label, a_out, b_out, valid_out, expected_a_out, expected_b_out, expected_valid_out);
    endtask

    initial begin
        int expected_acc;
        int pair_count;

        step("reset", 8'sd17, 8'sd19, 0);
        rst_n = 1'b1;

        int4_mode = 1'b1;
        expected_acc = 0;
        pair_count = 0;
        for (int a = -8; a <= 7; a++) begin
            for (int b = -8; b <= 7; b++) begin
                expected_acc += a * b;
                // Opposite upper-nibble signs expose accidental use of the full byte.
                step($sformatf("INT4 %0d * %0d", a, b), {4'ha, a[3:0]}, {4'h5, b[3:0]}, expected_acc);
                pair_count++;
            end
        end
        $display("PASS  All %0d signed INT4 operand pairs", pair_count);

        int4_mode = 1'b0;
        clear = 1'b1;
        step("clear with both operands valid", 8'sd9, 8'sd7, 0);
        clear = 1'b0;

        step("INT8 min * min", 8'sh80, 8'sh80, 16_384);
        step("INT8 min * max", 8'sh80, 8'sd127, 128);
        step("INT8 max * min", 8'sd127, 8'sh80, -16_128);
        step("INT8 max * max", 8'sd127, 8'sd127, 1);
        $display("PASS  All four signed INT8 extreme pairs");

        step("A invalid", 8'sd4, 8'sd7, 1, 2'b01);
        step("B invalid", 8'sd5, 8'sd9, 1, 2'b10);
        step("both operands invalid", 8'sd6, 8'sd11, 1, 2'b00);
        step("valid after bubbles", -8'sd3, 8'sd5, -14);
        $display("PASS  Valid bubbles and recovery");

        hold = 1'b1;
        step("hold with both operands valid", 8'sd8, 8'sd4, -14);
        step("hold with both operands invalid", 8'sd9, 8'sd3, -14, 2'b00);
        hold = 1'b0;
        step("resume after hold", 8'sd4, 8'sd5, 6);
        $display("PASS  Hold freezes the accumulator, operands, and valid bits");

        hold = 1'b1;
        clear = 1'b1;
        step("clear while held", 8'sd7, 8'sd6, 0, 2'b01);
        clear = 1'b0;
        hold = 1'b0;
        $display("PASS  Clear takes priority over valid input and hold");

        for (int i = 1; i <= 64; i++) begin
            step($sformatf("INT8 consecutive product %0d", i), 8'sh80, 8'sh80, i * 16_384);
        end
        $display("PASS  64 consecutive (-128 * -128) products accumulated to %0d", acc_out);

        rst_n = 1'b0;
        hold = 1'b1;
        step("reset while held with a nonzero accumulator", 8'sd9, 8'sd7, 0);
        rst_n = 1'b1;
        hold = 1'b0;
        step("resume after reset", 8'sd2, 8'sd3, 6);
        $display("PASS  Reset clears the accumulator and forwarding registers");

        $display("All tf_pe tests passed.");
        $finish;
    end
endmodule
