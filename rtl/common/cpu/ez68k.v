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

//requires fx68k module, but you can use any other similar 68k core.
module ez68k (
    input SYS_CLK,
    input RESET,
    input BUS_CS,
    input BUS_BUSY,
    input BUS_REQ,
    input PAUSE,
    input IPL0, IPL1, IPL2,
    output INTACKn,
    output [23:0] ADDR_8,
    input  [15:0] CPU_DIN,
    output [15:0] CPU_DOUT,
    output CPU_CEN,
    output RWn,
    output NEW_ADDR,
    output [1:0] DSn
);

parameter BASE_FREQ = 96_000_000;  // Base frequency in Hz (e.g., 50 MHz)
parameter TARGET_FREQ = 12_000_000; // Target frequency in Hz (e.g., 1 MHz)
parameter FAST_DTACK = 1; // Fast DTACK mode (1 for fast, 0 for slow)

wire [23:1] A;
wire UDSn, LDSn;
wire [23:0] addr_8 = {A[23:1], 1'b0}; //this makes it easier to follow the memory map.
wire RW;
assign RWn = RW; //active low
assign ADDR_8 = addr_8;

wire BUSn, ASn, LDSWn, UDSWn;
wire FC0, FC1, FC2;
wire inta_n = ~&{ FC0, FC1, FC2, ~ASn }; // ctrl like M68000's manual
assign INTACKn = inta_n; //active low.
wire VPAn = inta_n;
assign DSn = {UDSn, LDSn};
wire BRn, BGACKn, BGn, DTACKn;

assign NEW_ADDR = !ASn; //new address is available when ASn is low

wire cpu_base_cen; //2x the clock needed for the FX68K requirement.
generate_cen #(.BASE_FREQ(BASE_FREQ), .TARGET_FREQ(TARGET_FREQ*2), .RATIO_WIDTH(24))
cpu_input_frequency(SYS_CLK, cpu_base_cen);

//final CENs for fx68k
wire cpu_cena, cpu_cenb;
fx68k_cen cenab(SYS_CLK, RESET, cpu_base_cen, cpu_cena, cpu_cenb);

assign CPU_CEN = cpu_cena;

dtack_gen #(.FAST_DTACK(FAST_DTACK))
dtack_68k (
    .CLK(SYS_CLK),
    .RESET(RESET),
    .CPU_CEN(cpu_cena),
    .BUS_CS(BUS_CS),
    .BUS_BUSY(BUS_BUSY),
    .ASn(ASn),
    .DSn(DSn),
    .DTACKn(DTACKn)
);

busack_gen busack_gen (
    .CLK(SYS_CLK),
    .RESET(RESET),
    .CPU_CENB(cpu_cenb),
    .BGn(BGn),
    .ASn(ASn),
    .DTACKn(DTACKn),
    .BUS_REQ(BUS_REQ), //no special bus requests by default
    .BRn(BRn),
    .BGACKn(BGACKn)
);

fx68k u_cpu (
    .clk        (SYS_CLK),
    .extReset   (RESET),
    .pwrUp      (RESET),
    .enPhi1     (cpu_cena),
    .enPhi2     (cpu_cenb),

    // Buses
    .eab        (A),
    .iEdb       (CPU_DIN),
    .oEdb       (CPU_DOUT),

    .eRWn       (RW),
    .LDSn       (LDSn),
    .UDSn       (UDSn),
    .ASn        (ASn),
    .VPAn       (VPAn),
    .FC0        (FC0), 
    .FC1        (FC1),
    .FC2        (FC2),

    .BERRn      (1'b1),

    .HALTn      (PAUSE),
    .BRn        (BRn),
    .BGACKn     (BGACKn),
    .BGn        (BGn),

    .DTACKn     (DTACKn),
    .IPL0n      (IPL0),
    .IPL1n      (IPL1),
    .IPL2n      (IPL2),

    // Unused
    .oRESETn    (),
    .oHALTEDn   (),
    .VMAn       (),
    .E          ()
);
endmodule

module dtack_gen(
    input CLK,
    input RESET,
    input ASn,
    input [1:0] DSn,
    output reg DTACKn,
    input CPU_CEN,
    input BUS_CS,
    input BUS_BUSY
);

parameter FAST_DTACK = 1; // Fast DTACK mode (1 for fast, 0 for slow)

reg last_ASn;
reg last_DSn;
reg wait_cycle;
always @(posedge CLK or posedge RESET) begin
    if (RESET) begin
        DTACKn <= 1;
        wait_cycle <= 0;
        last_ASn <= 1;
    end else begin
        last_ASn <= ASn;

        // Reset DTACKn and begin wait on rising ASn
        if (last_ASn == 0 && ASn == 1) begin
            DTACKn <= 1;
            wait_cycle <= 1;
        end

        // If ASn is low (valid cycle) and bus is ready
        if (ASn == 0 && (wait_cycle == 0 || CPU_CEN)) begin
            if (!BUS_CS || (BUS_CS && !BUS_BUSY)) begin
                DTACKn <= 0;
                wait_cycle <= 0;
            end
        end
    end
end
endmodule

module fx68k_cen (
    input CLK,
    input RESET,
    input CEN, //this has to be 2x the intended CPU clock. ie. 24mhz if you want 12mhz operation.
    output reg ENPHI1, ENPHI2 //these are the actual CENs for the CPU, shifted 180 from eachother. it is half the CEN.
);

reg phase = 0;

always @(posedge CLK or posedge RESET) begin
    if (RESET) begin
        phase   <= 1'b0;
        ENPHI1  <= 1'b0;
        ENPHI2  <= 1'b0;
    end else if (CEN) begin
        phase <= ~phase;
        ENPHI1 <= ~phase;  // pulse high for 1 cycle when phase == 0
        ENPHI2 <= phase;   // pulse high for 1 cycle when phase == 1
    end else begin
        ENPHI1 <= 1'b0;
        ENPHI2 <= 1'b0;
    end
end

endmodule

module busack_gen (
    input CLK,
    input RESET,
    input CPU_CENB,
    input BGn, ASn, DTACKn,
    input BUS_REQ,
    output reg BRn, BGACKn
);

always @(posedge CLK)
    if(RESET) begin
        BRn    <= 1'b1;
        BGACKn <= 1'b1;
    end else begin
        casez({BRn, BGn, BGACKn})
            3'b111:
                if(BUS_REQ) begin
                    BRn <= 1'b0;                    
                end
            3'b001: begin
                if(ASn && DTACKn) BGACKn <= 1'b0;
            end
            3'b??0: begin
                BRn  <= 1'b1;
                if( !BUS_REQ ) begin
                    BGACKn <= 1'b1;
                end
            end
        endcase
    end
endmodule