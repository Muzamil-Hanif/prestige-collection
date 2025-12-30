#!/usr/bin/env python3
"""
Adjust padding around app icon by scaling the content
Usage: python3 adjust_icon_padding.py [scale_factor]
Example: python3 adjust_icon_padding.py 0.6  (for more padding)
         python3 adjust_icon_padding.py 0.8  (for less padding)
"""

import sys
import os

try:
    from PIL import Image
except ImportError:
    print("Installing Pillow...")
    os.system("pip3 install pillow --quiet")
    from PIL import Image

def add_padding_to_icon(input_path, output_path, scale_factor=0.7, bg_color=(255, 255, 255)):
    """
    Add padding around icon by scaling it down and placing on background
    
    Args:
        input_path: Path to input image
        output_path: Path to output image
        scale_factor: How much to scale down (0.7 = 70% of original size)
        bg_color: Background color (R, G, B) tuple
    """
    try:
        # Open the image
        img = Image.open(input_path)
        
        # Convert to RGB if needed
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Calculate new size (scaled down)
        original_width, original_height = img.size
        new_width = int(original_width * scale_factor)
        new_height = int(original_height * scale_factor)
        
        # Resize the image
        resized_img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # Create a new image with white background (same size as original)
        padded_img = Image.new('RGB', (original_width, original_height), bg_color)
        
        # Calculate position to center the resized image
        x_offset = (original_width - new_width) // 2
        y_offset = (original_height - new_height) // 2
        
        # Paste the resized image onto the white background
        padded_img.paste(resized_img, (x_offset, y_offset))
        
        # Save the result
        padded_img.save(output_path, 'PNG')
        print(f"✓ Successfully updated {output_path} with padding")
        print(f"  Original size: {original_width}x{original_height}")
        print(f"  Scaled content: {new_width}x{new_height} ({scale_factor*100:.0f}% of original)")
        print(f"  Padding: ~{x_offset}px on each side")
        return True
    except Exception as e:
        print(f"✗ Error processing image: {e}")
        return False

if __name__ == "__main__":
    input_file = "assets/images/prestige-men-logo-V4-white-bg.png"
    output_file = "assets/images/prestige-men-logo-V4-white-bg.png"
    
    # Get scale factor from command line or use default
    if len(sys.argv) > 1:
        try:
            scale_factor = float(sys.argv[1])
            if not 0.1 <= scale_factor <= 1.0:
                print("Scale factor must be between 0.1 and 1.0")
                sys.exit(1)
        except ValueError:
            print("Invalid scale factor. Use a number between 0.1 and 1.0")
            sys.exit(1)
    else:
        # Default: 70% size = 30% padding
        scale_factor = 0.7
    
    if not os.path.exists(input_file):
        print(f"✗ Input file not found: {input_file}")
        sys.exit(1)
    
    print(f"Adjusting icon padding (scale: {scale_factor*100:.0f}%)...")
    if add_padding_to_icon(input_file, output_file, scale_factor):
        print(f"\n✓ Icon updated!")
        print(f"  To regenerate app icons, run: flutter pub run flutter_launcher_icons")
        print(f"\n  To adjust padding again:")
        print(f"    More padding:    python3 adjust_icon_padding.py 0.5")
        print(f"    Current padding: python3 adjust_icon_padding.py 0.7")
        print(f"    Less padding:    python3 adjust_icon_padding.py 0.8")
    else:
        sys.exit(1)

