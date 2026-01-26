```bash
docker build -t dee-timelock .
```

```bash
docker run --rm dee-timelock dee --version
docker run --rm dee-timelock dee remote
```

```bash
cat data.txt | docker run --rm -i dee-timelock dee crypt -u quicknet -r 3d > data.dee
docker run --rm -i dee-timelock dee crypt --decrypt < data.dee > data.decrypted
```