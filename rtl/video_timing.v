module video_timing (
    input               clk,
    input               cen,
    input               reset,

    input        [15:0] crtc0,
    input        [15:0] crtc1,
    input        [15:0] crtc2,
    input        [15:0] crtc3,

    input               refresh_mod,

    input signed [4:0]  hs_offset,
    input signed [4:0]  vs_offset,

    input signed [4:0]  hs_width,
    input signed [4:0]  vs_width,

    output       [8:0]  hc,
    output       [8:0]  vc,

    output reg          hbl_delay,
    output reg          hsync,
    output reg          vbl,
    output reg          vsync,
    output reg          crtc_ready
);

// Fall back 320x240 timings (black frame)
localparam [8:0] HTOTAL_D  = 9'd450;
localparam [8:0] HBSTART_D = 9'd320;
localparam [8:0] HBL_CNT_D = HTOTAL_D - HBSTART_D;

localparam [8:0] VTOTAL_D  = 9'd270;
localparam [8:0] VBSTART_D = 9'd240;
localparam [8:0] VBL_CNT_D = VTOTAL_D - VBSTART_D;

wire crtc_init = (crtc0[7:0] != 8'd0) && (crtc2[7:0] != 8'd0);
always @(posedge clk) begin
    if(reset) begin
        crtc_ready <= 1'b0;
    end else if(cen && !crtc_ready && crtc_init) begin
        crtc_ready <= 1'b1;
    end
end

wire [8:0] HTOTAL_EFF  = crtc_ready ? HTOTAL  : HTOTAL_D;
wire [8:0] HBL_CNT_EFF = crtc_ready ? HBL_CNT : HBL_CNT_D;
wire [8:0] HBSTART_EFF = HTOTAL_EFF - HBL_CNT_EFF;

wire [8:0] VTOTAL_EFF  = crtc_ready ? VTOTAL  : VTOTAL_D;
wire [8:0] VBL_CNT_EFF = crtc_ready ? VBL_CNT : VBL_CNT_D;
wire [8:0] VBSTART_EFF = VTOTAL_EFF - VBL_CNT_EFF;

// 320x240 timings
wire [8:0] HBL_CNT = { crtc0[15:8]-1, 1'b1 };
wire [8:0] HTOTAL  = { crtc0[7:0], 1'b1 }; // horz total clocks and blank start
wire [8:0] HBSTART = HTOTAL - HBL_CNT; // horz blank begin

wire [8:0] HSSTART = 360 + $signed(hs_offset) - (refresh_mod ? 4'd4 : 3'd0); // horz sync begin
wire [8:0] HSEND   = 380 + $signed(hs_offset) + $signed(hs_offset) + (refresh_mod ? 4'd4 : 3'd0); // horz sync end

wire [8:0] VBL_CNT = { crtc2[15:8], 1'b1 };
wire [8:0] VTOTAL  = { crtc2[7:0], 1'b1 };
wire [8:0] VBSTART = VTOTAL - VBL_CNT;

wire [8:0] VSSTART = 250 + $signed(vs_offset);
wire [8:0] VSEND   = 253 + $signed(vs_offset) + $signed(vs_width);

reg hbl;
reg [8:0] v;
reg [8:0] h;

assign hc = h;
assign vc = v;

reg [1:0] vtotal_282_flag;
always @(posedge clk) begin // set horz lines flag for ntsc
    if(cen) begin
        if(VTOTAL == 269)
            vtotal_282_flag <= 0;
        else
            vtotal_282_flag <= 1;
    end
end

always @(posedge clk) begin
    if(reset) begin
        h <= 0;
        v <= 0;
        hbl <= 0;
        hbl_delay <= 0;
        vbl <= 0;
        hsync <= 0;
        vsync <= 0;
    end else if(cen) begin
        // counter
        hbl_delay <= hbl;
        if(h == HTOTAL_EFF - (refresh_mod ? 4'd5 : 3'd0)) begin // 450 lines (445 lines for ntsc)
            h <= 0;
            hbl <= 0;

            // v signals
            if(v == VBSTART_EFF-1) begin
                vbl <= 1;
            end else if(v == VSSTART) begin
                vsync <= 0;
            end else if(v == VSEND) begin
                vsync <= 1;
            end

            if(v == VTOTAL_EFF - (refresh_mod ? (vtotal_282_flag ? 5'd19 : 4'd7) : 3'd0)) begin // 282 lines standard (263 lines for ntsc)
                v <= 0;
                vbl <= 0;
            end else begin
                v <= v + 1'd1;
            end
        end else begin
            h <= h + 1'd1;
        end

        // h signals
        if(h == HBSTART_EFF-1) begin
            hbl <= 1;
        end else if(h == HSSTART) begin
            hsync <= 0;
        end else if(h == HSEND) begin
            hsync <= 1;
        end
    end
end

endmodule
