#!/usr/bin/env bash
#
# timelock-crypt.sh
# Encrypt / decrypt files using dee-timelock (quicknet + release time)
#

set -euo pipefail

# Defaults
NETWORK="quicknet"
DEFAULT_TIME="3d"
MODE="encrypt"  # encrypt or decrypt

show_help() {
    echo "Usage: $(basename "$0") [options] file(s)"
    echo
    echo "Options:"
    echo "  -t TIME     Lock time (encrypt only)   ex: 7d, 48h   [default: ${DEFAULT_TIME}]"
    echo "  -n NETWORK  Network name               [default: ${NETWORK}]"
    echo "  -d          Decrypt mode (instead of encrypt)"
    echo "  -h          Show this help"
    echo
    echo "Examples:"
    echo "  # Encrypt"
    echo "  $(basename "$0") document.pdf"
    echo "  $(basename "$0") -t 7d contract.docx"
    echo "  $(basename "$0") -t 48h -n testnet report.txt"
    echo
    echo "  # Decrypt"
    echo "  $(basename "$0") -d locked-file.dee"
    echo "  $(basename "$0") -d secret.dee"
    exit 1
}

# Parse arguments
while getopts "t:n:dh" opt; do
    case $opt in
        t) TIME="$OPTARG" ;;
        n) NETWORK="$OPTARG" ;;
        d) MODE="decrypt" ;;
        h) show_help ;;
        \?) show_help ;;
    esac
done
shift $((OPTIND-1))

if [ $# -eq 0 ]; then
    echo "Error: provide at least one file"
    show_help
fi

# Process each file
for file in "$@"; do

    if [ ! -f "$file" ]; then
        echo "File not found: $file"
        continue
    fi

    if [ "$MODE" = "encrypt" ]; then
        # Encrypt
        if [ ! -v TIME ]; then TIME="$DEFAULT_TIME"; fi

        output="${file}.dee"

        echo "Encrypting  → $file"
        echo "   Network  → $NETWORK"
        echo "   Time     → $TIME"
        echo "   Output   → $output"

        cat "$file" | \
            docker run --rm -i dee-timelock dee crypt -u "$NETWORK" -r "$TIME" \
            > "$output"

    else
        # Decrypt
        if [[ "$file" != *.dee ]]; then
            echo "Warning: file does not end with .dee → $file"
        fi

        output="${file%.dee}.decrypted"

        echo "Decrypting  → $file"
        echo "   Output   → $output"

        docker run --rm -i dee-timelock dee crypt --decrypt < "$file" \
            > "$output"
    fi

    if [ $? -eq 0 ] && [ -s "$output" ]; then
        echo "OK → $output created"
        echo
    else
        echo "Error processing $file"
        rm -f "$output" 2>/dev/null
    fi

done

echo "Done."