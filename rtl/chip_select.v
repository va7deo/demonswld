module chip_select (
    // variant
    input  [7:0]  pcb,

    // m68k addressing
    input [23:0]  cpu_a,
    input         cpu_as_n,

    // z80 addressing
    input [15:0]  z80_addr,
    input         MREQ_n,
    input         IORQ_n,

    // M68K selects
    output wire   prog_rom_cs,
    output wire   ram_cs,
    output wire   scroll_ofs_x_cs,
    output wire   scroll_ofs_y_cs,
    output wire   frame_done_cs,
    output wire   int_en_cs,
    output wire   crtc_cs,
    output wire   tile_ofs_cs,
    output wire   tile_attr_cs,
    output wire   tile_num_cs,
    output wire   scroll_cs,
    output wire   shared_ram_cs,
    output wire   vblank_cs,
    output wire   tile_palette_cs,
    output wire   bcu_flip_cs,
    output wire   sprite_palette_cs,
    output wire   sprite_ofs_cs,
    output wire   sprite_cs,
    output wire   sprite_size_cs,
    output wire   sprite_ram_cs,
    output wire   fcu_flip_cs,
    output wire   reset_z80_cs,
    output wire   dsp_ctrl_cs,

    // Z80 selects
    output wire   z80_p1_cs,
    output wire   z80_p2_cs,
    output wire   z80_dswa_cs,
    output wire   z80_dswb_cs,
    output wire   z80_system_cs,
    output wire   z80_tjump_cs,
    output wire   z80_sound0_cs,
    output wire   z80_sound1_cs,

    // other params
    output [15:0] scroll_y_offset
);

localparam demonwld  = 'h00;
localparam demonwld1 = 'h01;
localparam demonwld2 = 'h02;
localparam demonwld3 = 'h03;
localparam demonwld4 = 'h04;
localparam demonwld5 = 'h05;

function m68k_cs;
        input [23:0] start_address;
        input [23:0] end_address;
begin
    m68k_cs = ( cpu_a[23:0] >= start_address && cpu_a[23:0] <= end_address) & !cpu_as_n;
end
endfunction

function z80_cs;
        input [7:0] address_lo;
begin
    z80_cs = ( IORQ_n == 0 && z80_addr[7:0] == address_lo );
end
endfunction

assign scroll_y_offset = 16;

assign prog_rom_cs       = m68k_cs( 24'h000000, 24'h03ffff );

assign vblank_cs         = m68k_cs( 24'h400000, 24'h400001 );
assign int_en_cs         = m68k_cs( 24'h400002, 24'h400003 );
assign crtc_cs           = m68k_cs( 24'h400008, 24'h40000f );

assign tile_palette_cs   = m68k_cs( 24'h404000, 24'h4047ff );
assign sprite_palette_cs = m68k_cs( 24'h406000, 24'h4067ff );

assign shared_ram_cs     = m68k_cs( 24'h600000, 24'h600fff );

assign bcu_flip_cs       = m68k_cs( 24'h800000, 24'h800001 );
assign tile_ofs_cs       = m68k_cs( 24'h800002, 24'h800003 );
assign tile_attr_cs      = m68k_cs( 24'h800004, 24'h800005 );
assign tile_num_cs       = m68k_cs( 24'h800006, 24'h800006 );
assign scroll_cs         = m68k_cs( 24'h800010, 24'h80001f );

assign frame_done_cs     = m68k_cs( 24'ha00000, 24'ha00001 );
assign sprite_ofs_cs     = m68k_cs( 24'ha00002, 24'ha00003 );
assign sprite_cs         = m68k_cs( 24'ha00004, 24'ha00005 );
assign sprite_size_cs    = m68k_cs( 24'ha00006, 24'ha00007 );

assign ram_cs            = m68k_cs( 24'hc00000, 24'hc03fff );

assign scroll_ofs_x_cs   = m68k_cs( 24'he00000, 24'he00001 );
assign scroll_ofs_y_cs   = m68k_cs( 24'he00002, 24'he00003 );
assign fcu_flip_cs       = m68k_cs( 24'he00006, 24'he00007 );

assign reset_z80_cs      = m68k_cs( 24'he00008, 24'he00009 );

assign dsp_ctrl_cs       = m68k_cs( 24'he0000a, 24'he0000b );

assign z80_p1_cs         = z80_cs( 8'h80 );
assign z80_p2_cs         = z80_cs( 8'hc0 );
assign z80_dswa_cs       = z80_cs( 8'he0 );
assign z80_dswb_cs       = z80_cs( 8'ha0 );
assign z80_system_cs     = z80_cs( 8'h60 );
assign z80_tjump_cs      = z80_cs( 8'h20 );
assign z80_sound0_cs     = z80_cs( 8'h00 );
assign z80_sound1_cs     = z80_cs( 8'h01 );

endmodule
