## tlock - Timelock File Encryption Tool

A bash script wrapper for encrypting and decrypting files using drand timelock encryption. Available as a single Docker image on Docker Hub.

### What it does?
tlock.sh allows you to:

 - 🔒 Encrypt files that can only be decrypted after a specified time period
 - 🔓 Decrypt files once the timelock period has elapsed


## Setup

### Option 1: Docker Hub (recommended)

Pull the image and use it directly — no local installation required:

```bash
docker pull nicolashuber/tlock-crypt:latest
```

### Option 2: Build from source

```bash
git clone https://github.com/nicolashuber/tlock-crypt.git
cd tlock-crypt
docker build -t nicolashuber/tlock-crypt .
```

### Option 3: Install tlock.sh locally

Requires `dee` to be installed and available in your PATH.

```bash
# Make the script executable
chmod +x tlock.sh

# Optionally, move to your PATH
sudo mv tlock.sh /usr/local/bin/tlock
```

## Usage

### Using Docker (recommended)

```bash
# Encrypt (default: 3 days)
docker run --rm -v $(pwd):/data nicolashuber/tlock-crypt:latest document.pdf

# Encrypt with custom lock time
docker run --rm -v $(pwd):/data nicolashuber/tlock-crypt:latest -t 7d contract.docx

# Decrypt
docker run --rm -v $(pwd):/data nicolashuber/tlock-crypt:latest -d document.pdf.tlock

# Show help
docker run --rm nicolashuber/tlock-crypt:latest -h
```

> **Note:** Mount your working directory to `/data` inside the container so tlock can access your files.

### Using tlock.sh directly

```bash
# Basic encryption (default: 3 days)
./tlock.sh document.pdf

# Specify lock time
./tlock.sh -t 7d contract.docx
./tlock.sh -t 48h report.txt
./tlock.sh -t 2h presentation.pptx
```

**Time formats:**
- `h` - hours (e.g., `24h`, `48h`)
- `d` - days (e.g., `3d`, `7d`)

### Decrypt Files

```bash
# Decrypt a timelocked file
./tlock.sh -d document.pdf.tlock

# The original filename is automatically restored
# document.pdf.tlock → document.pdf
```

### Options

| Flag | Description | Example |
|------|-------------|---------|
| `-t TIME` | Lock duration | `-t 7d` (7 days) |
| `-n NETWORK` | Drand network | `-n quicknet` (default) |
| `-d` | Decrypt mode | `-d` |
| `-h` | Show help | `-h` |