/*
* <-- pr4m0d -->
* https://pram0d.com
* https://twitter.com/pr4m0d
* https://github.com/psomashekar
*
* Copyright © 2025 Pramod Somashekar / Copyright © 2025 Coin-Op Collection
*
* This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/
*
* You may use, share, and modify this code for non-commercial purposes, provided that proper credit is given.
*/

module generate_cen #(
    // Fixed input clock frequency and desired output frequency.
    parameter BASE_FREQ   = 50_000_000,  // e.g., 50 MHz
    parameter TARGET_FREQ = 1_000_000,   // e.g., 1 MHz
    // Parameters for pulse output width and fractional arithmetic.
    parameter EDGE_WIDTH  = 2,
    parameter RATIO_WIDTH = 10,
    parameter SHIFTED_CEN = 0 // 1: generate half-phase pulse, 0: no half-phase pulse
)(
    input  CLK,
    input  RESET, //ie. pll not locked yet, etc.
    output [EDGE_WIDTH-1:0] CEN   // Main enable pulse
);
    reg [EDGE_WIDTH-1:0] cen;   // Main enable pulse
    reg [EDGE_WIDTH-1:0] cenb;   // 180° shifted (half-phase) enable pulse
    assign CEN = (SHIFTED_CEN ? cenb : cen);

    //--------------------------------------------------------------------------
    // Helper: Compute the Greatest Common Divisor (GCD) at compile time.
    function integer gcd;
        input integer a, b;
        integer temp;
        begin
            while (b != 0) begin
                temp = b;
                b = a % b;
                a = temp;
            end
            gcd = a;
        end
    endfunction

    //--------------------------------------------------------------------------
    // Compute a simplified ratio.
    // For a fractional divider that produces an output frequency equal to
    // BASE_FREQ * (STEP / LIM), we need STEP/LIM = TARGET_FREQ/BASE_FREQ.
    // Thus, we set:
    //      STEP = TARGET_FREQ / gcd(TARGET_FREQ, BASE_FREQ)
    //      LIM  = BASE_FREQ   / gcd(TARGET_FREQ, BASE_FREQ)
    localparam integer COMMON_DIV = gcd(TARGET_FREQ, BASE_FREQ);
    localparam integer STEP_INT = TARGET_FREQ / COMMON_DIV;  // Numerator
    localparam integer LIM_INT  = BASE_FREQ   / COMMON_DIV;   // Denominator

    localparam IS_INTEGER_MODE = (BASE_FREQ % TARGET_FREQ == 0);
    localparam DIVISOR = BASE_FREQ / TARGET_FREQ;

    // Registers for integer division
    reg [$clog2(DIVISOR)-1:0] div_cnt = 0;
    reg half_phase = 0;

    // Represent these as fixed-point values.
    localparam [RATIO_WIDTH:0] STEP = STEP_INT;
    localparam [RATIO_WIDTH:0] LIM  = LIM_INT;
    // For safety, define an upper bound for the accumulator.
    localparam [RATIO_WIDTH:0] ABSMAX = LIM + STEP;

    
    generate
        if (STEP_INT >= (1 << (RATIO_WIDTH + 1)) || LIM_INT >= (1 << (RATIO_WIDTH + 1))) begin : ratio_width_check
            // Will trigger a Quartus error if left unguarded
            if(STEP_INT >= (1 << (RATIO_WIDTH + 1)))
                ERROR_STEP_ratio_width_too_small dummy(); // force an error message
            if(LIM_INT >= (1 << (RATIO_WIDTH + 1)))
                ERROR_LIM_ratio_width_too_small dummy2(); // force an error message
        end
    endgenerate

    //--------------------------------------------------------------------------
    // Fractional accumulator and half-phase flag.
    reg [RATIO_WIDTH:0] cencnt = 0;
    reg half = 0;  // Indicates whether the half-phase pulse has been generated

    // Calculate the next accumulator value.
    wire [RATIO_WIDTH:0] sum = cencnt + STEP;
    // A main event occurs when the sum reaches or exceeds LIM.
    wire main_event = (sum >= LIM);
    // A half event occurs when sum crosses half of LIM and hasn't been triggered yet.
    wire half_event = (sum >= (LIM >> 1)) && (!half);

    //--------------------------------------------------------------------------
    // Edge counters for pulse shaping.
    reg [EDGE_WIDTH-1:0] edgecnt    = 0;
    reg [EDGE_WIDTH-1:0] edgecnt_b  = 0;
    wire [EDGE_WIDTH-1:0] next_edgecnt   = edgecnt + 1;
    wire [EDGE_WIDTH-1:0] next_edgecnt_b = edgecnt_b + 1;
    wire [EDGE_WIDTH-1:0] toggle   = next_edgecnt   & ~edgecnt;
    wire [EDGE_WIDTH-1:0] toggle_b = next_edgecnt_b & ~edgecnt_b;

    //--------------------------------------------------------------------------
    // Main process: update the accumulator and generate pulses.
    always @(posedge CLK or posedge RESET) begin
        if(RESET) begin
            cen <= 0;
            cenb <= 0;
            cencnt <= 0;
            half <= 0;
            edgecnt <= 0;
            edgecnt_b <= 0;
            div_cnt <= 0;
            half_phase <= 0;
        end else begin
            // Default: disable pulses.
            cen  <= 0;
            cenb <= 0;

            if(IS_INTEGER_MODE) begin
                if (div_cnt == DIVISOR - 1) begin
                    div_cnt <= 0;
                    edgecnt <= next_edgecnt;
                    cen <= { toggle[EDGE_WIDTH-2:0], 1'b1 };
                    half_phase <= 0;
                end else begin
                    div_cnt <= div_cnt + 1;
                    if (SHIFTED_CEN && !half_phase && div_cnt == (DIVISOR >> 1)) begin
                        edgecnt_b <= next_edgecnt_b;
                        cenb <= { toggle_b[EDGE_WIDTH-2:0], 1'b1 };
                        half_phase <= 1;
                    end
                end
            end else begin
            
                // Safety: If the accumulator ever exceeds its allowed maximum, reset it.
                if (cencnt >= ABSMAX) begin
                    cencnt <= 0;
                    half   <= 0;
                end 
                else begin
                    // Check for a main event (full-cycle pulse).
                    if (main_event) begin
                        // Wrap the accumulator: subtract LIM from the sum.
                        cencnt <= sum - LIM;
                        // Clear the half flag so a new half pulse can occur next cycle.
                        half <= 0;
                        // Update the main pulse edge counter and generate the main pulse.
                        edgecnt <= next_edgecnt;
                        cen <= { toggle[EDGE_WIDTH-2:0], 1'b1 };
                    end 
                    else begin
                        // No main event: simply update the accumulator.
                        cencnt <= sum;
                        // If we haven't yet generated the half-phase pulse and we're past
                        // the midpoint, generate the half-phase pulse.
                        if (half_event) begin
                            half <= 1;
                            edgecnt_b <= next_edgecnt_b;
                            cenb <= { toggle_b[EDGE_WIDTH-2:0], 1'b1 };
                        end
                    end
                end
            end
        end
    end

endmodule

