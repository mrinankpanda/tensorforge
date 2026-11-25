`timescale 1ns/1ps

module tf_pe (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               clear,
    input  logic               hold,
    input  logic               int4_mode,
    input  logic signed [7:0]  a_in,
    input  logic signed [7:0]  b_in,
    input  logic               a_valid_in,
    input  logic               b_valid_in,
    output logic signed [7:0]  a_out,
    output logic signed [7:0]  b_out,
    output logic               a_valid_out,
    output logic               b_valid_out,
    output logic signed [31:0] acc_out
);
    logic signed [7:0]  a_operand, b_operand;
    logic signed [15:0] product;
    logic signed [31:0] extended_product;

    // INT4 uses the low nibble of each input byte, with bit 3 as the sign.
    assign a_operand = int4_mode ? {{4{a_in[3]}}, a_in[3:0]} : a_in;
    assign b_operand = int4_mode ? {{4{b_in[3]}}, b_in[3:0]} : b_in;
    assign product = a_operand * b_operand;
    assign extended_product = {{16{product[15]}}, product};

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            a_out       <= '0;
            b_out       <= '0;
            a_valid_out <= 1'b0;
            b_valid_out <= 1'b0;
            acc_out     <= '0;
        end else begin
            // Forward the original bytes and each stream's valid bit.
            if (!hold) begin
                a_out       <= a_in;
                b_out       <= b_in;
                a_valid_out <= a_valid_in;
                b_valid_out <= b_valid_in;
            end

            // Clear has priority over hold for the accumulator.
            if (clear)
                acc_out <= '0;
            else if (!hold && a_valid_in && b_valid_in)
                acc_out <= acc_out + extended_product;
        end
    end
endmodule
