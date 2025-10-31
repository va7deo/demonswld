/*
* <-- pr4m0d -->
* https://pram0d.com
* https://twitter.com/pr4m0d
* https://github.com/psomashekar
*
* <-- Coin-Op Collection -->
* https://coinopcollection.org
* https://twitter.com/_atrac17
* https://github.com/Coin-OpCollection/
*
* Copyright © 2025 Pramod Somashekar / Copyright © 2025 Coin-Op Collection
*
* This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/.
*
* You may use, share, and modify this code for non-commercial purposes, provided that proper credit is given.
*/

module audio_mixer #(
    parameter integer               CH_NM = 6,             // Number of channels
    parameter integer               WM    = 16,            // Internal fixed width
    parameter integer               WOUT  = 16,            // Output width
    parameter integer               WD    = 4,             // Fractional width
    parameter integer               WA    = WM + 8,        // Width after gain multiplication
    parameter integer               WS    = WA + 3,        // Width for accumulation
    parameter integer               WI    = WS - WD,       // Width after truncating decimals
    parameter         [CH_NM*5-1:0] W     = {CH_NM{5'd16}} // Packed per-channel widths (5-bit each)
)(
    input wire                       RESET,
    input wire                       CLK,
    input wire signed [CH_NM*WM-1:0] CH,
    input wire         [CH_NM*8-1:0] GAIN,
    output wire signed    [WOUT-1:0] MIX_OUT,
    output wire                      PEAK
);

// Clipping Limiter
localparam signed [WM+3:0] POS = {5'b0, {WM-1{1'b1}}};
localparam signed [WM+3:0] NEG = {~5'b0, {WM-1{1'b0}}};

wire signed [WM-1:0] CH_EXT [0:CH_NM-1];
wire signed    [8:0] GAIN_SIGNED [0:CH_NM-1];
wire signed [WA-1:0] SCALED [0:CH_NM-1];

genvar i;
generate
    for(i = 0; i < CH_NM; i = i + 1) begin : PER_CH
        wire signed [WM-1:0] raw_ch;

        assign raw_ch = CH[i*WM +: WM];
        assign GAIN_SIGNED[i] = {1'b0, GAIN[i*8 +: 8]};

        if(W[i*5 +: 5] == 5'd16)
            assign CH_EXT[i] = raw_ch;
        else if(W[i*5 +: 5] == 5'd15)
            assign CH_EXT[i] = {{1{raw_ch[14]}}, raw_ch[14:0]};
        else if(W[i*5 +: 5] == 5'd14)
            assign CH_EXT[i] = {{2{raw_ch[13]}}, raw_ch[13:0]};
        else if(W[i*5 +: 5] == 5'd13)
            assign CH_EXT[i] = {{3{raw_ch[12]}}, raw_ch[12:0]};
        else if(W[i*5 +: 5] == 5'd12)
            assign CH_EXT[i] = {{4{raw_ch[11]}}, raw_ch[11:0]};
        else if(W[i*5 +: 5] == 5'd11)
            assign CH_EXT[i] = {{5{raw_ch[10]}}, raw_ch[10:0]};
        else if(W[i*5 +: 5] == 5'd10)
            assign CH_EXT[i] = {{6{raw_ch[9]}}, raw_ch[9:0]};
        else if(W[i*5 +: 5] == 5'd9)
            assign CH_EXT[i] = {{7{raw_ch[8]}}, raw_ch[8:0]};
        else if(W[i*5 +: 5] == 5'd8)
            assign CH_EXT[i] = {{8{raw_ch[7]}}, raw_ch[7:0]};
        else if(W[i*5 +: 5] == 5'd7)
            assign CH_EXT[i] = {{9{raw_ch[6]}}, raw_ch[6:0]};
        else if(W[i*5 +: 5] == 5'd6)
            assign CH_EXT[i] = {{10{raw_ch[5]}}, raw_ch[5:0]};
        else if(W[i*5 +: 5] == 5'd5)
            assign CH_EXT[i] = {{11{raw_ch[4]}}, raw_ch[4:0]};
        else if(W[i*5 +: 5] == 5'd4)
            assign CH_EXT[i] = {{12{raw_ch[3]}}, raw_ch[3:0]};
        else if(W[i*5 +: 5] == 5'd3)
            assign CH_EXT[i] = {{13{raw_ch[2]}}, raw_ch[2:0]};
        else if(W[i*5 +: 5] == 5'd2)
            assign CH_EXT[i] = {{14{raw_ch[1]}}, raw_ch[1:0]};
        else if(W[i*5 +: 5] == 5'd1)
            assign CH_EXT[i] = {{15{raw_ch[0]}}, raw_ch[0:0]};
        else
            assign CH_EXT[i] = {WM{1'b0}};

        assign SCALED[i] = CH_EXT[i] * GAIN_SIGNED[i];
    end
endgenerate

// Registers and accumulation
reg signed [WA-1:0] gain_reg [0:CH_NM-1];
reg signed [WS-1:0] sum_extended;
reg signed [WI-1:0] sum_truncated, sum_clamped;
reg signed [WM-1:0] final_out;

function [WS-1:0] sext;
    input [WA-1:0] a;
    begin
        sext = {{WS-WA{a[WA-1]}}, a};
    end
endfunction

integer j;
always @(*) begin
    sum_extended = 0;
    for(j = 0; j < CH_NM; j = j + 1)
        sum_extended = sum_extended + sext(gain_reg[j]);
    sum_truncated = sum_extended[WS-1:WD];
end

wire clip = sum_truncated[WI-1:WM] != {WI-WM{sum_truncated[WM-1]}};

assign MIX_OUT = final_out[WM-1:WM-WOUT];
assign PEAK    = clip;

integer k;
always @(posedge CLK) begin
    if(RESET) begin
        for(k = 0; k < CH_NM; k = k + 1)
            gain_reg[k] <= 0;
        sum_clamped <= 0;
        final_out <= 0;
    end else begin
        for(k = 0; k < CH_NM; k = k + 1)
            gain_reg[k] <= SCALED[k];
        sum_clamped <= sum_truncated;
        final_out <= clip ? (sum_clamped[WI-1] ? NEG[WM-1:0] : POS[WM-1:0]) : sum_clamped[WM-1:0];
    end
end

endmodule

// -----------------------------------------------------------------------------
//            Mono Linear Amplifier Using Flattened Parametric Mixer            
// -----------------------------------------------------------------------------

module linear_amp #(
    parameter WIN  = 16,
    parameter WOUT = 16
)(
    input wire                    RESET,
    input wire                    CLK,
    input wire signed   [WIN-1:0] SAMPLE_IN,
    input wire              [7:0] GAIN,
    output wire signed [WOUT-1:0] SAMPLE_OUT,
    output wire                   PEAK
);

audio_mixer #(
    .CH_NM ( 1        ),
    .WM    ( WIN      ),
    .WOUT  ( WOUT     ),
    .W     ( {5'd16}  )
) u_amp (
    .RESET   ( RESET       ),
    .CLK     ( CLK         ),
    .CH      ( {SAMPLE_IN} ),
    .GAIN    ( {GAIN}      ),
    .MIX_OUT ( SAMPLE_OUT  ),
    .PEAK    ( PEAK        )
);

endmodule
