# wsl-rootfs
Simplest WSL rootfs building method.

```
apt-get install umoci skopeo ca-certificates
skopeo copy docker://ubuntu:24.04 oci:./ubuntu_24_04_oci:24.04
umoci raw unpack --image ./ubuntu_24_04_oci:24.04 ./rootfs
tar czvf ubuntu2404.tar.gz -C rootfs .
```
