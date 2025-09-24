#!/bin/bash

# Simple script to enlarge screenshots with optimal settings
# Usage: ./enlarge_screenshot.sh input_image.png [scale_factor]

# Default settings optimized for screenshots
SCALE=${2:-2.5}  # Default 2.5x enlargement
METHOD="lanczos"  # Best quality for text/screenshots

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🖼️  Screenshot Enlarger${NC}"
echo -e "${BLUE}=====================${NC}"

# Check if input file provided
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Error: Please provide an image file${NC}"
    echo "Usage: $0 <input_image> [scale_factor]"
    echo "Example: $0 russell_jewelers.png 2.5"
    exit 1
fi

INPUT_FILE="$1"

# Check if file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo -e "${RED}❌ Error: File '$INPUT_FILE' not found${NC}"
    exit 1
fi

echo -e "${BLUE}📁 Input file:${NC} $INPUT_FILE"
echo -e "${BLUE}🔍 Scale factor:${NC} ${SCALE}x"
echo -e "${BLUE}⚙️  Quality method:${NC} $METHOD"
echo ""

# Run the enlargement
echo -e "${BLUE}🚀 Processing image...${NC}"
python3 enlarge_image.py "$INPUT_FILE" -s "$SCALE" -m "$METHOD"

# Check if successful
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Success! Your screenshot has been enlarged.${NC}"
    echo -e "${GREEN}📊 The enlarged image is now ${SCALE}x larger and much easier to read!${NC}"
else
    echo -e "${RED}❌ Error occurred during processing${NC}"
    exit 1
fi