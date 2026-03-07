#!/usr/bin/env bats

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# Preparação
setup() {
  TEST_DIR="$(mktemp -d)"
  TEST_FILE="$TEST_DIR/testfile.txt"
  echo "isto é um texto de teste" > "$TEST_FILE"

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

# Testar script
@test "Tlock deve estar disponível para execução" {
  run bash "$SCRIPT_DIR/tlock.sh" -h
  [[ "$output" == *"Usage"* ]]
}

@test "Tlock deve criptografar corretamente um arquivo" {
  run bash "$SCRIPT_DIR/tlock.sh" "$TEST_FILE"
  [ "$status" -eq 0 ]
  [ -f "${TEST_FILE}.tlock" ]
}

@test "Tlock deve descriptografar corretamente um arquivo" {
  bash "$SCRIPT_DIR/tlock.sh" "$TEST_FILE"
  run bash "$SCRIPT_DIR/tlock.sh" -d "${TEST_FILE}.tlock"
  [ "$status" -eq 0 ]
  [ -f "$TEST_FILE" ]
  diff <(echo "isto é um texto de teste") "$TEST_FILE"
}

@test "Tlock deve exibir erro com argumentos inválidos" {
  run bash "$SCRIPT_DIR/tlock.sh"
  [ "$status" -ne 0 ]
}
