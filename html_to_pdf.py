#!/usr/bin/env python3
"""
HTML to PDF Converter Script

This script converts HTML files to PDF using WeasyPrint.
Usage: python html_to_pdf.py <input_html_file> [output_pdf_file]
"""

import sys
import os
from pathlib import Path

def convert_html_to_pdf(html_file, pdf_file=None):
    """Convert HTML file to PDF"""
    try:
        # Import weasyprint
        from weasyprint import HTML, CSS
        from weasyprint.text.fonts import FontConfiguration
        
        # Validate input file
        if not os.path.exists(html_file):
            print(f"Error: HTML file '{html_file}' not found.")
            return False
            
        # Set output file name if not provided
        if pdf_file is None:
            html_path = Path(html_file)
            pdf_file = html_path.with_suffix('.pdf')
        
        print(f"Converting '{html_file}' to '{pdf_file}'...")
        
        # Create font configuration
        font_config = FontConfiguration()
        
        # Convert HTML to PDF
        html_doc = HTML(filename=html_file)
        html_doc.write_pdf(pdf_file, font_config=font_config)
        
        print(f"✅ Successfully converted to '{pdf_file}'")
        return True
        
    except ImportError:
        print("Error: WeasyPrint not installed. Please install it first:")
        print("pip install weasyprint")
        return False
    except Exception as e:
        print(f"Error during conversion: {e}")
        return False

def main():
    if len(sys.argv) < 2:
        print("Usage: python html_to_pdf.py <input_html_file> [output_pdf_file]")
        print("\nExample:")
        print("  python html_to_pdf.py index.html")
        print("  python html_to_pdf.py index.html output.pdf")
        sys.exit(1)
    
    html_file = sys.argv[1]
    pdf_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    success = convert_html_to_pdf(html_file, pdf_file)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()