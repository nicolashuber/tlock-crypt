#!/usr/bin/env bats

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# Utility to calculate SHA256 hash of a file
calculate_hash() {
  sha256sum "$1" | awk '{print $1}'
}

setup() {
  TEST_DIR="$(mktemp -d)"
  PDF_FILE="$TEST_DIR/testfile.pdf"
  ZIP_FILE="$TEST_DIR/testfile.zip"

  # Create a minimal PDF file (PDF magic bytes + test content)
  printf '%%PDF-1.4\nTest PDF content for tlock testing\n' > "$PDF_FILE"

  # Create a ZIP file with sample content
  echo "Texto dentro do zip" > "$TEST_DIR/inner.txt"
  (cd "$TEST_DIR" && zip testfile.zip inner.txt)

  # Create a mock docker command to avoid requiring real Docker + dee-timelock
  mkdir -p "$TEST_DIR/bin"
  cat > "$TEST_DIR/bin/docker" << 'DOCKER_EOF'
#!/usr/bin/env bash
# Mock docker: pass stdin to stdout for testing purposes
cat
DOCKER_EOF
  chmod +x "$TEST_DIR/bin/docker"

  # Prepend the mock bin directory to PATH so tlock.sh uses the mock docker
  export PATH="$TEST_DIR/bin:$PATH"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "Tlock criptografa e descriptografa PDF corretamente" {
  local original_hash
  original_hash=$(calculate_hash "$PDF_FILE")

  run bash "$SCRIPT_DIR/tlock.sh" "$PDF_FILE"
  [ "$status" -eq 0 ]
  [ -f "${PDF_FILE}.tlock" ]

  bash "$SCRIPT_DIR/tlock.sh" -d "${PDF_FILE}.tlock"
  [ -f "$PDF_FILE" ]

  local decrypted_hash
  decrypted_hash=$(calculate_hash "$PDF_FILE")
  [ "$original_hash" = "$decrypted_hash" ]
}

@test "Tlock criptografa e descriptografa ZIP corretamente" {
  local original_hash
  original_hash=$(calculate_hash "$ZIP_FILE")

  run bash "$SCRIPT_DIR/tlock.sh" "$ZIP_FILE"
  [ "$status" -eq 0 ]
  [ -f "${ZIP_FILE}.tlock" ]

  bash "$SCRIPT_DIR/tlock.sh" -d "${ZIP_FILE}.tlock"
  [ -f "$ZIP_FILE" ]

  local decrypted_hash
  decrypted_hash=$(calculate_hash "$ZIP_FILE")
  [ "$original_hash" = "$decrypted_hash" ]
}

@test "Tlock exibe erro para arquivo inexistente" {
  run bash "$SCRIPT_DIR/tlock.sh" "$TEST_DIR/nonexistent.pdf"
  [[ "$output" == *"File not found"* ]]
}

@test "Tlock exibe erro ao processar arquivo vazio" {
  local empty_file="$TEST_DIR/empty.pdf"
  touch "$empty_file"
  run bash "$SCRIPT_DIR/tlock.sh" "$empty_file"
  [ "$status" -ne 0 ]
}
