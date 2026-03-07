## tlock - Timelock File Encryption Tool

A bash script wrapper for encrypting and decrypting files using drand timelock encryption via the dee-timelock Docker container.

### What it does?
tlock.sh allows you to:

 - 🔒 Encrypt files that can only be decrypted after a specified time period
 - 🔓 Decrypt files once the timelock period has elapsed


## Setup

### Prerequisites

- Docker installed and running
- `dee-timelock` Docker image

### Install dee-timelock

```bash
# Pull the dee-timelock Docker image
docker pull dee-timelock

# Or build it from source if you have the repository
# docker build -t dee-timelock .
```

### Install tlock.sh

```bash
# Make the script executable
chmod +x tlock.sh

# Optionally, move to your PATH
sudo mv tlock.sh /usr/local/bin/tlock
```

## Usage

### Encrypt Files

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