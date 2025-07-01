#!/bin/bash
# Kleuren (optioneel)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'
# Emoji’s als unicode codes
CHECKMARK='✅'
CROSSMARK='❌'   
WARNING='⚠️''
PACKAGE='📦'
HOURGLASS='⏳'
CHART='📊'
STOPWATCH='⏱''   

# Functie om Node.js te controleren
check_node() {
  if ! command -v node &> /dev/null; then
    echo -e "${RED}${CROSSMARK} Node.js is niet geïnstalleerd.${NC}"
    echo -e "${YELLOW}Installeer Node.js eerst: https://nodejs.org/${NC}"
    exit 1
  fi
  echo -e "${GREEN}${CHECKMARK} Node.js gevonden: $(node --version)${NC}"
}
# Functie om npm te controleren
check_npm() {
  if ! command -v npm &> /dev/null; then
    echo -e "${RED}${CROSSMARK} npm is niet geïnstalleerd.${NC}"
    echo -e "${YELLOW}npm wordt meestal met Node.js meegeïnstalleerd.${NC}"
    exit 1
  fi
  echo -e "${GREEN}${CHECKMARK} npm gevonden: $(npm --version)${NC}"
}
# Functie om xeokit-convert te installeren
install_xeokit_convert() {
  echo -e "${YELLOW}${PACKAGE} xeokit-convert wordt geïnstalleerd...${NC}"
  # Probeer globaal te installeren (kan sudo rechten vereisen)
  if npm install -g @xeokit/xeokit-convert; then
    echo -e "${GREEN}${CHECKMARK} xeokit-convert succesvol geïnstalleerd (globaal)${NC}"
  else
    echo -e "${YELLOW}${WARNING}  Globale installatie mislukt, probeer met sudo...${NC}"
    if sudo npm install -g @xeokit/xeokit-convert; then
      echo -e "${GREEN}${CHECKMARK} xeokit-convert succesvol geïnstalleerd met sudo${NC}"
    else
      echo -e "${RED}${CROSSMARK} Installatie mislukt. Probeer handmatig:${NC}"
      echo "sudo npm install -g @xeokit/xeokit-convert"
      exit 1
    fi
  fi
}
# Functie om xeokit-convert te controleren
check_xeokit_convert() {
  if ! command -v xeokit-convert &> /dev/null; then
    echo -e "${YELLOW}${WARNING}  xeokit-convert is niet geïnstalleerd.${NC}"
    # Vraag om bevestiging voor installatie
    read -p "Wil je xeokit-convert nu installeren? (j/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Jj]$ ]]; then
      check_node
      check_npm
      install_xeokit_convert
    else
      echo -e "${RED}${CROSSMARK} Installatie geannuleerd. xeokit-convert is vereist.${NC}"
      exit 1
    fi
  else
    echo -e "${GREEN}${CHECKMARK} xeokit-convert gevonden${NC}"
  fi
}
# Hoofdscript begint hier
echo -e "${GREEN}=== IFC naar XKT Converter ===${NC}"
# Controleer dependencies
check_xeokit_convert
# Input controleren
if [ -z "$1" ]; then
  echo -e "${RED}${CROSSMARK} Geef een IFC-bestand op als eerste argument.${NC}"
  echo "Gebruik: $0 input.ifc [output.xkt]"
  exit 1
fi
INPUT_FILE="$1"
if [ ! -f "$INPUT_FILE" ]; then
  echo -e "${RED}${CROSSMARK} Bestand niet gevonden: $INPUT_FILE${NC}"
  exit 1
fi
# Controleer of het een IFC-bestand is
if [[ ! "$INPUT_FILE" =~ \.ifc$ ]]; then
  echo -e "${YELLOW}${WARNING}  Waarschuwing: Het bestand heeft geen .ifc extensie${NC}"
fi
# Output-bestand bepalen
if [ -n "$2" ]; then
  OUTPUT_FILE="$2"
else
  # Vervang extensie .ifc door .xkt
  OUTPUT_FILE="${INPUT_FILE%.*}.xkt"
fi
# Maak log directory aan als die niet bestaat
LOG_DIR="logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/conversie_$(date +%Y%m%d).log"
# Logging
DATE_START=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$DATE_START] ${CHECKMARK} Start conversie: $INPUT_FILE naar $OUTPUT_FILE" | tee -a "$LOG_FILE"
# Toon bestandsgrootte
FILE_SIZE=$(du -h "$INPUT_FILE" | cut -f1)
echo "${CHART} Bestandsgrootte: $FILE_SIZE" | tee -a "$LOG_FILE"
# Conversie uitvoeren met voortgang
echo -e "${YELLOW}${HOURGLASS} Conversie bezig...${NC}"
if xeokit-convert -s "$INPUT_FILE" -o "$OUTPUT_FILE" 2>&1 | tee -a "$LOG_FILE"; then
  DATE_END=$(date '+%Y-%m-%d %H:%M:%S')
  # Controleer of output bestand bestaat
  if [ -f "$OUTPUT_FILE" ]; then
    OUTPUT_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo -e "[$DATE_END] ${GREEN}${CHECKMARK} Conversie gelukt: $OUTPUT_FILE (grootte: $OUTPUT_SIZE)${NC}" | tee -a "$LOG_FILE"
    # Bereken conversietijd
    START_SECONDS=$(date -d "$DATE_START" +%s)
    END_SECONDS=$(date -d "$DATE_END" +%s)
    DURATION=$((END_SECONDS - START_SECONDS))
    echo "${STOPWATCH} Conversietijd: $DURATION seconden" | tee -a "$LOG_FILE"
  else
    echo -e "[$DATE_END] ${RED}${CROSSMARK} Output bestand niet aangemaakt${NC}" | tee -a "$LOG_FILE"
    exit 1
  fi
else
  DATE_END=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "[$DATE_END] ${RED}${CROSSMARK} Conversie mislukt voor: $INPUT_FILE${NC}" | tee -a "$LOG_FILE"
  echo -e "${YELLOW}${WARNING} Tip: Controleer of het IFC-bestand geldig is${NC}"
  exit 1
fi
