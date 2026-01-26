#!/usr/bin/env bash
#
# timelock-crypt.sh
# Encrypt / decrypt files using dee-timelock (quicknet + release time)
#

set -euo pipefail

# Color codes
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_CYAN='\033[0;36m'
COLOR_RESET='\033[0m'

# Helper functions for colored output
print_error() {
    echo -e "${COLOR_RED}✗ $*${COLOR_RESET}"
}

print_success() {
    echo -e "${COLOR_GREEN}✓ $*${COLOR_RESET}"
}

print_warning() {
    echo -e "${COLOR_YELLOW}⚠ $*${COLOR_RESET}"
}

print_info() {
    echo -e "${COLOR_BLUE}ℹ $*${COLOR_RESET}"
}

print_highlight() {
    echo -e "${COLOR_CYAN}→ $*${COLOR_RESET}"
}

# Defaults
NETWORK="quicknet"
DEFAULT_TIME="3d"
MODE="encrypt"  # encrypt or decrypt
DELETE_ORIGINAL=false

show_help() {
    echo "Usage: $(basename "$0") [options] file(s)"
    echo
    echo "Options:"
    echo "  -t TIME     Lock time (encrypt only)   ex: 7d, 48h   [default: ${DEFAULT_TIME}]"
    echo "  -n NETWORK  Network name               [default: ${NETWORK}]"
    echo "  -d          Decrypt mode (instead of encrypt)"
    echo "  -r          Remove original file after encryption"
    echo "  -h          Show this help"
    echo
    echo "Examples:"
    echo "  # Encrypt"
    echo "  $(basename "$0") document.pdf"
    echo "  $(basename "$0") -t 7d contract.docx"
    echo "  $(basename "$0") -t 48h -n testnet report.txt"
    echo "  $(basename "$0") -r secret.txt           # Remove original after encryption"
    echo
    echo "  # Decrypt"
    echo "  $(basename "$0") -d locked-file.tlock"
    echo "  $(basename "$0") -d secret.tlock"
    exit 1
}

# Parse arguments
while getopts "t:n:drh" opt; do
    case $opt in
        t) TIME="$OPTARG" ;;
        n) NETWORK="$OPTARG" ;;
        d) MODE="decrypt" ;;
        r) DELETE_ORIGINAL=true ;;
        h) show_help ;;
        \?) show_help ;;
    esac
done
shift $((OPTIND-1))

if [ $# -eq 0 ]; then
    echo "Error: provide at least one file"
    show_help
fi

# Function to run docker command
run_docker() {
    docker run --rm -i dee-timelock dee "$@"
}

# Function to encrypt a file
encrypt_file() {
    local file="$1"
    local time="${2:-$DEFAULT_TIME}"
    local output="${file}.tlock"

    print_highlight "Encrypting: $file"
    print_info "   Network: $NETWORK"
    print_info "   Time: $time"
    print_info "   Output: $output"

    cat "$file" | run_docker crypt -u "$NETWORK" -r "$time" > "$output"

    if [ $? -eq 0 ] && [ -s "$output" ]; then
        print_success "$output created"
        
        if [ "$DELETE_ORIGINAL" = true ]; then
            rm -f "$file"
            print_info "   Original file deleted: $file"
        fi
        
        echo
        return 0
    else
        print_error "Error processing $file"
        rm -f "$output" 2>/dev/null
        return 1
    fi
}

# Function to decrypt a file
decrypt_file() {
    local file="$1"
    local temp_output="${file%.tlock}.decrypted"
    local final_output="${file%.tlock}"

    if [[ "$file" != *.tlock ]]; then
        print_warning "File does not end with .tlock: $file"
    fi

    print_highlight "Decrypting: $file"
    print_info "   Output: $final_output"

    run_docker crypt --decrypt < "$file" > "$temp_output"

    if [ $? -eq 0 ] && [ -s "$temp_output" ]; then
        # Rename removing .tlock extension
        mv "$temp_output" "$final_output"
        
        # Delete the .tlock file after successful decryption
        rm -f "$file"
        
        print_success "$final_output created"
        print_info "   Encrypted file deleted: $file"
        echo
        return 0
    else
        print_error "Error processing $file"
        rm -f "$temp_output" 2>/dev/null
        return 1
    fi
}

# Process each file
for file in "$@"; do

    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        continue
    fi

    if [ "$MODE" = "encrypt" ]; then
        if [ ! -v TIME ]; then TIME="$DEFAULT_TIME"; fi
        encrypt_file "$file" "$TIME"
    else
        decrypt_file "$file"
    fi

done

print_success "Done."