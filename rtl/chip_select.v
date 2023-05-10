//

module chip_select
(
    input  [7:0] pcb,

    input [23:0] cpu_a,
    input        cpu_as_n,

    input [15:0] z80_addr,
    input        MREQ_n,
    input        IORQ_n,

    // M68K selects
    output       prog_rom_cs,
    output       ram_cs,
    output       scroll_ofs_x_cs,
    output       scroll_ofs_y_cs,
    output       frame_done_cs,
    output       int_en_cs,
    output       crtc_cs,
    output       tile_ofs_cs,
    output       tile_attr_cs,
    output       tile_num_cs,
    output       scroll_cs,
    output       shared_ram_cs,
    output       vblank_cs,
    output       tile_palette_cs,
    output       bcu_flip_cs,
    output       sprite_palette_cs,
    output       sprite_ofs_cs,
    output       sprite_cs,
    output       sprite_size_cs,
    output       sprite_ram_cs,
    output       fcu_flip_cs,
    output       reset_z80_cs,
    output       dsp_ctrl_cs,
    output       dsp_addr_cs,
    output       dsp_r_cs,
    output       dsp_bio_cs,

    // Z80 selects
    output       z80_p1_cs,
    output       z80_p2_cs,
    output       z80_dswa_cs,
    output       z80_dswb_cs,
    output       z80_system_cs,
    output       z80_tjump_cs,
    output       z80_sound0_cs,
    output       z80_sound1_cs,

    // other params
    output reg [15:0] scroll_y_offset
);

localparam pcb_demonwld      = 0;

function m68k_cs;
        input [23:0] base_address;
        input  [7:0] width;
begin
    m68k_cs = ( cpu_a >> width == base_address >> width ) & !cpu_as_n;
end
endfunction

function z80_cs;
        input [7:0] address_lo;
begin
    z80_cs = ( IORQ_n == 0 && z80_addr[7:0] == address_lo );
end
endfunction

always @(*) begin

    if (pcb == pcb_demonwld) begin
        scroll_y_offset = 16;
    end else begin
        scroll_y_offset = 0;
    end


    // Setup lines depending on pcb
    case (pcb)
        pcb_demonwld: begin
            prog_rom_cs       = m68k_cs( 'h000000, 18 );

            ram_cs            = m68k_cs( 'hc00000, 14 );

            scroll_ofs_x_cs   = m68k_cs( 'he00000,  1 );
            scroll_ofs_y_cs   = m68k_cs( 'he00002,  1 );
            fcu_flip_cs       = m68k_cs( 'he00006,  1 );

            vblank_cs         = m68k_cs( 'h400000,  1 );
            int_en_cs         = m68k_cs( 'h400002,  1 );
            crtc_cs           = m68k_cs( 'h400008,  3 );

            tile_palette_cs   = m68k_cs( 'h404000, 11 );
            sprite_palette_cs = m68k_cs( 'h406000, 11 );

            shared_ram_cs     = m68k_cs( 'h600000, 12 );

            bcu_flip_cs       = m68k_cs( 'h800001,  1 );
            tile_ofs_cs       = m68k_cs( 'h800002,  1 );
            tile_attr_cs      = m68k_cs( 'h800004,  1 );
            tile_num_cs       = m68k_cs( 'h800006,  1 );
            scroll_cs         = m68k_cs( 'h800010,  4 );

            frame_done_cs     = m68k_cs( 'ha00000,  1 );
            sprite_ofs_cs     = m68k_cs( 'ha00002,  1 );
            sprite_cs         = m68k_cs( 'ha00004,  1 );
            sprite_size_cs    = m68k_cs( 'ha00006,  1 );

            reset_z80_cs      = m68k_cs( 'he00008,  1 );

            //dsp_ctrl_cs       = m68k_cs( 'he0000b,  1 );
            //dsp_addr_cs       = m68k_cs( 4'h0 );
            //dsp_r_cs          = m68k_cs( 4'h1 );
            //dsp_bio_cs        = m68k_cs( 4'h3 );

            z80_p1_cs         = z80_cs( 8'h80 );
            z80_p2_cs         = z80_cs( 8'hc0 );
            z80_dswa_cs       = z80_cs( 8'he0 );
            z80_dswb_cs       = z80_cs( 8'ha0 );
            z80_system_cs     = z80_cs( 8'h60 );
            z80_tjump_cs      = z80_cs( 8'h20 );
            z80_sound0_cs     = z80_cs( 8'h00 );
            z80_sound1_cs     = z80_cs( 8'h01 );
        end

        default:;
    endcase
end

endmodule
