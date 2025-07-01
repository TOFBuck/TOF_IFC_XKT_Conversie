#!/bin/bash

# Kleuren (optioneel)
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Input controleren
if [ -z "$1" ]; then
  echo -e "${RED}❌ Geef een IFC-bestand op als eerste argument.${NC}"
  echo "Gebruik: $0 input.ifc [output.xkt]"
  exit 1
fi

INPUT_FILE="$1"

if [ ! -f "$INPUT_FILE" ]; then
  echo -e "${RED}❌ Bestand niet gevonden: $INPUT_FILE${NC}"
  exit 1
fi

# Output-bestand bepalen
if [ -n "$2" ]; then
  OUTPUT_FILE="$2"
else
  # Vervang extensie .ifc door .xkt
  OUTPUT_FILE="${INPUT_FILE%.*}.xkt"
fi

# Logging
DATE_START=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$DATE_START] ✅ Start conversie: $INPUT_FILE naar $OUTPUT_FILE" | tee -a log.txt

# Conversie uitvoeren
if xeokit-convert -s "$INPUT_FILE" -o "$OUTPUT_FILE"; then
  DATE_END=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "[$DATE_END] ${GREEN}✅ Conversie gelukt: $OUTPUT_FILE${NC}" | tee -a log.txt
else
  DATE_END=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "[$DATE_END] ${RED}❌ Conversie mislukt voor: $INPUT_FILE${NC}" | tee -a log.txt
  exit 1
fi
