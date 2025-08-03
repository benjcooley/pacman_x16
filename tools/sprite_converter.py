#!/usr/bin/env python3
"""
Sprite Converter for Commander X16
Converts Pacman ROM sprite data to 1bpp VERA format
"""

def convert_4bpp_to_1bpp(sprite_data_4bpp):
    """Convert 4bpp sprite data to 1bpp format"""
    sprite_1bpp = []
    
    # Process 8 rows of 8 pixels each
    for row in range(8):
        byte_val = 0
        for col in range(8):
            # Get pixel from 4bpp data (2 pixels per byte)
            byte_idx = row * 4 + col // 2
            if col % 2 == 0:
                # Even column - upper nibble
                pixel = (sprite_data_4bpp[byte_idx] >> 4) & 0xF
            else:
                # Odd column - lower nibble  
                pixel = sprite_data_4bpp[byte_idx] & 0xF
            
            # Convert to 1bpp: non-zero = 1, zero = 0
            if pixel > 0:
                byte_val |= (1 << (7 - col))
        
        sprite_1bpp.append(byte_val)
    
    return sprite_1bpp

# Pacman sprite data from ROM (right-facing, mouth open)
pacman_right_open_4bpp = [
    0x00, 0x0F, 0xFF, 0xF0,  # Row 0: "  ####  "
    0x00, 0xFF, 0xFF, 0xFF,  # Row 1: " ###### "
    0x0F, 0xFF, 0xFF, 0xFF,  # Row 2: "########"
    0xFF, 0xFF, 0xFF, 0x00,  # Row 3: "####    "
    0xFF, 0xFF, 0xFF, 0x00,  # Row 4: "####    "
    0x0F, 0xFF, 0xFF, 0xFF,  # Row 5: "########"
    0x00, 0xFF, 0xFF, 0xFF,  # Row 6: " ###### "
    0x00, 0x0F, 0xFF, 0xF0,  # Row 7: "  ####  "
]

# Pacman sprite data (right-facing, mouth closed)
pacman_right_closed_4bpp = [
    0x00, 0x0F, 0xFF, 0xF0,  # Row 0: "  ####  "
    0x00, 0xFF, 0xFF, 0xFF,  # Row 1: " ###### "
    0x0F, 0xFF, 0xFF, 0xFF,  # Row 2: "########"
    0xFF, 0xFF, 0xFF, 0xFF,  # Row 3: "########"
    0xFF, 0xFF, 0xFF, 0xFF,  # Row 4: "########"
    0x0F, 0xFF, 0xFF, 0xFF,  # Row 5: "########"
    0x00, 0xFF, 0xFF, 0xFF,  # Row 6: " ###### "
    0x00, 0x0F, 0xFF, 0xF0,  # Row 7: "  ####  "
]

# Ghost sprite data (normal state)
ghost_normal_4bpp = [
    0x00, 0x0F, 0xFF, 0xFF,  # Row 0: "  ######"
    0x0F, 0xFF, 0xFF, 0xFF,  # Row 1: " #######"
    0xFF, 0xFF, 0x0F, 0xFF,  # Row 2: "#### ###"
    0xFF, 0xFF, 0xFF, 0xFF,  # Row 3: "########"
    0xFF, 0xFF, 0xFF, 0xFF,  # Row 4: "########"
    0xFF, 0xFF, 0xFF, 0xFF,  # Row 5: "########"
    0xFF, 0xFF, 0xFF, 0xFF,  # Row 6: "########"
    0xFF, 0x0F, 0xFF, 0x0F,  # Row 7: "# ## # #"
]

# Frightened ghost sprite data
ghost_frightened_4bpp = [
    0x00, 0x0F, 0xFF, 0xFF,  # Row 0: "  ######"
    0x0F, 0x33, 0x33, 0x33,  # Row 1: " #######" (different color)
    0x33, 0x33, 0x0F, 0x33,  # Row 2: "#### ###" (different color)
    0x33, 0x33, 0x33, 0x33,  # Row 3: "########" (different color)
    0x33, 0x33, 0x33, 0x33,  # Row 4: "########" (different color)
    0x33, 0x33, 0x33, 0x33,  # Row 5: "########" (different color)
    0x33, 0x33, 0x33, 0x33,  # Row 6: "########" (different color)
    0x33, 0x0F, 0x33, 0x0F,  # Row 7: "# ## # #" (different color)
]

# Dot sprite data
dot_4bpp = [
    0x00, 0x00, 0x00, 0x00,  # Row 0: "        "
    0x00, 0x00, 0x00, 0x00,  # Row 1: "        "
    0x00, 0x00, 0x00, 0x00,  # Row 2: "        "
    0x00, 0x00, 0xFF, 0xFF,  # Row 3: "   ##   "
    0x00, 0x00, 0xFF, 0xFF,  # Row 4: "   ##   "
    0x00, 0x00, 0x00, 0x00,  # Row 5: "        "
    0x00, 0x00, 0x00, 0x00,  # Row 6: "        "
    0x00, 0x00, 0x00, 0x00,  # Row 7: "        "
]

# Power pellet sprite data
power_pellet_4bpp = [
    0x00, 0x00, 0xFF, 0xFF,  # Row 0: "  ####  "
    0x00, 0xFF, 0xFF, 0xFF,  # Row 1: " ###### "
    0xFF, 0xFF, 0xFF, 0xFF,  # Row 2: "########"
    0xFF, 0xFF, 0xFF, 0xFF,  # Row 3: "########"
    0xFF, 0xFF, 0xFF, 0xFF,  # Row 4: "########"
    0xFF, 0xFF, 0xFF, 0xFF,  # Row 5: "########"
    0x00, 0xFF, 0xFF, 0xFF,  # Row 6: " ###### "
    0x00, 0x00, 0xFF, 0xFF,  # Row 7: "  ####  "
]

def generate_asm_sprite(name, sprite_data_1bpp):
    """Generate assembly code for a 1bpp sprite"""
    lines = [f"{name}:"]
    for i, byte_val in enumerate(sprite_data_1bpp):
        lines.append(f"    .byte ${byte_val:02X}")
    return "\n".join(lines)

def main():
    print("; Pacman 1bpp Sprite Data for Commander X16")
    print("; Converted from original Pacman ROM data")
    print()
    
    # Convert all sprites to 1bpp
    sprites = {
        "pacman_right_open": convert_4bpp_to_1bpp(pacman_right_open_4bpp),
        "pacman_right_closed": convert_4bpp_to_1bpp(pacman_right_closed_4bpp),
        "ghost_normal": convert_4bpp_to_1bpp(ghost_normal_4bpp),
        "ghost_frightened": convert_4bpp_to_1bpp(ghost_frightened_4bpp),
        "dot": convert_4bpp_to_1bpp(dot_4bpp),
        "power_pellet": convert_4bpp_to_1bpp(power_pellet_4bpp),
    }
    
    # Generate assembly output
    for name, data in sprites.items():
        print(generate_asm_sprite(name, data))
        print()
    
    # Generate palette information
    print("; Palette colors (from original Pacman ROM)")
    print("; COLOR_PACMAN     = $09  ; Yellow")
    print("; COLOR_BLINKY     = $01  ; Red") 
    print("; COLOR_PINKY      = $03  ; Pink")
    print("; COLOR_INKY       = $05  ; Cyan")
    print("; COLOR_CLYDE      = $07  ; Orange")
    print("; COLOR_FRIGHTENED = $11  ; Blue")
    print("; COLOR_DOT        = $10  ; White/Yellow")
    print()
    
    # Show visual representation
    print("; Visual representation:")
    for name, data in sprites.items():
        print(f"; {name}:")
        for byte_val in data:
            visual = ""
            for bit in range(8):
                if byte_val & (1 << (7 - bit)):
                    visual += "#"
                else:
                    visual += " "
            print(f";   {visual}")
        print()

if __name__ == "__main__":
    main()
