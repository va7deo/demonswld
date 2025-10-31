# Toaplan (Demon's World) FPGA Implementation
FPGA-compatible core of Toaplan Version 1 arcade hardware for MiSTerFPGA, written by **Erin Olafson**. The core is based on OutZone schematics and verified against Demon's World (TP-016).
The intent of this core is to deliver a 1:1 gameplay-accurate FPGA implementation of Toaplan V1 hardware. This core is in active development with assistance from **atrac17**.

## Supported Titles
| Title                                                                             | PCB<br>Number |
|-----------------------------------------------------------------------------------|---------------|
| [**Demon's World / Horror Story**](https://en.wikipedia.org/wiki/Demon%27s_World) | TP-016        |

## External Modules
| Module                                                                             | Function                                                               | Author                                      |
|------------------------------------------------------------------------------------|------------------------------------------------------------------------|---------------------------------------------|
| [**fx68k**](https://github.com/ijor/fx68k)                                         | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Jorge Cwik                                  |
| [**t80**](https://opencores.org/projects/t80)                                      | [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)           | Daniel Wallner                              |
| [**IKA32010**](https://github.com/ika-musume/IKA32010)                             | [**TMS32010**](https://en.wikipedia.org/wiki/Texas_Instruments_TMS320) | Sehyeon Kim                                 |
| [**opl2_fpga**](https://github.com/gtaylormb/opl2_fpga_MiSTer)                     | [**Yamaha OPL2**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2)       | Greg Taylor                                 |
| [**mem**](https://github.com/MiSTer-devel/Arcade-Rygar_MiSTer/tree/master/src/mem) | SDRAM Controller / ROM Downloader                                      | Josh Bassett; modified by Erin Olafson      |
| [**core_template**](https://github.com/MiSTer-devel/Template_MiSTer)               | MiSTer Framework Template                                              | sorgelig; modified by Erin Olafson, atrac17 |
| [**COC-Modules**]( )                                                               | K3 Framework Modules                                                   | Pramod Somashekar, atrac17                  |

# Known Issues / Tasks
- **None**

# PCB Check List
### Clock Information
| H-Sync       | V-Sync      | Source    | PCB<br>Number |
|--------------|-------------|-----------|---------------|
| 15.556938kHz | 55.161153Hz | DSLogic + | TP-018        |

**Pixel clock:** 7.00 MHz

**Geometry:**

    450 pixels/line  
    282 lines/frame  

### Crystal Oscillators
| Freq (MHz) | Use                                                                                 |
|------------|-------------------------------------------------------------------------------------|
| 10.00      | M68000 CLK (10 MHz)                                                                 |
| 28.000     | Z80 CLK (3.5 MHz)<br>YM3812 CLK (3.5 MHz)<br>Pixel CLK (7 MHz)<br> DSP CLK (14 MHz) |

### Main Components
| Chip                                                                   | Function         |
|------------------------------------------------------------------------|------------------|
| [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Main CPU         |
| [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)           | Sound CPU        |
| [**TMS32010**](https://en.wikipedia.org/wiki/Texas_Instruments_TMS320) | DSP & Protection |
| [**Yamaha YM3812**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2)     | OPL2 Audio       |

### Custom Components
| Chip                                             | Function           |
|--------------------------------------------------|--------------------|
| **NEC D65081R077**                               | Custom Gate-Array  |
| **FCU-02**                                       | Sprite RAM         |
| **FDA MN53007T0A / TOAPLAN-02 M70H005 / GXL-02** | Sprite Counter     |
| **BCU-02**                                       | Tile Map Generator |

# PCB Information
| Title                            | Joystick | Service Menu                                                                                                 | Dip Switches                                                                                              | Shared Controls | Dip Default | PCB Information                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
|----------------------------------|----------|--------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|-----------------|-------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Demon's World / Horror Story** | 8-Way    | [**Service Menu**](https://github.com/va7deo/demonswld/assets/32810066/f7de88ca-ea44-443a-ba6e-251cf99c3735) | [**Dip Sheet**](https://github.com/va7deo/demonswld/assets/32810066/d2a8547d-6663-4b10-ae7f-eb5e307bf127) | Co-Op           | N/A         | There are significant differences between the five sets, but only minimal differences among the regional variants. Set 3 is the polished version and has been chosen as the primary. Aside from difficulty, all sets share the same enemy roster, though the stage order differs. <br><br>Sets 1 and 2 feature the same stage order but different enemy sprites. Sets 3, 4, and 5 share the same stage order, with variations in enemy patterns and sprites. <br><br>To pause the game, press P2 Start; press P1 Start to resume. A slow-motion debug mode can be activated by pressing P1 Start and P2 Start simultaneously. The third button functions as a "Rapid Shot," though this feature is undocumented in both the manual and the service menu, where button 3 is listed as unused. |

# Licensing
Contact the author for special licensing needs. Otherwise follow the GPLv2 license attached.
