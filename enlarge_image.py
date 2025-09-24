#!/usr/bin/env python3
"""
Image Enlargement Script
Enlarges PNG/JPG images while preserving quality using different resampling methods.
"""

import os
import sys
from PIL import Image, ImageFilter
import argparse

def enlarge_image(input_path, output_path=None, scale_factor=2.0, method='lanczos'):
    """
    Enlarge an image by a given scale factor.
    
    Args:
        input_path (str): Path to input image
        output_path (str): Path for output image (optional)
        scale_factor (float): Factor by which to enlarge (e.g., 2.0 = double size)
        method (str): Resampling method ('lanczos', 'bicubic', 'bilinear', 'nearest')
    """
    
    # Validate input file
    if not os.path.exists(input_path):
        raise FileNotFoundError(f"Input file not found: {input_path}")
    
    # Open the image
    try:
        with Image.open(input_path) as img:
            # Get original dimensions
            original_width, original_height = img.size
            
            # Calculate new dimensions
            new_width = int(original_width * scale_factor)
            new_height = int(original_height * scale_factor)
            
            print(f"Original size: {original_width}x{original_height}")
            print(f"New size: {new_width}x{new_height}")
            print(f"Scale factor: {scale_factor}x")
            print(f"Resampling method: {method}")
            
            # Choose resampling method
            resampling_methods = {
                'lanczos': Image.Resampling.LANCZOS,
                'bicubic': Image.Resampling.BICUBIC,
                'bilinear': Image.Resampling.BILINEAR,
                'nearest': Image.Resampling.NEAREST
            }
            
            resampling = resampling_methods.get(method.lower(), Image.Resampling.LANCZOS)
            
            # Resize the image
            enlarged_img = img.resize((new_width, new_height), resampling)
            
            # Generate output path if not provided
            if output_path is None:
                name, ext = os.path.splitext(input_path)
                output_path = f"{name}_enlarged_{scale_factor}x{ext}"
            
            # Save the enlarged image
            enlarged_img.save(output_path, quality=95, optimize=True)
            
            print(f"Enlarged image saved to: {output_path}")
            return output_path
            
    except Exception as e:
        raise Exception(f"Error processing image: {str(e)}")

def main():
    parser = argparse.ArgumentParser(description='Enlarge images while preserving quality')
    parser.add_argument('input', help='Input image path')
    parser.add_argument('-o', '--output', help='Output image path (optional)')
    parser.add_argument('-s', '--scale', type=float, default=2.0, 
                       help='Scale factor (default: 2.0)')
    parser.add_argument('-m', '--method', default='lanczos',
                       choices=['lanczos', 'bicubic', 'bilinear', 'nearest'],
                       help='Resampling method (default: lanczos)')
    
    args = parser.parse_args()
    
    try:
        enlarge_image(args.input, args.output, args.scale, args.method)
        print("✅ Image enlargement completed successfully!")
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()