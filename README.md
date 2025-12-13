# wsl-rootfs
Simplest WSL rootfs building method.

## tagname list

```bash
skopeo list-tags docker://"$IMAGENAME" | jq -r .Tags[]
```
