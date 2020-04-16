# ISSO in Docker
For this to work with WSL you need to do the following:
```sh
sudo mdkir /c
sudo mount --bind /mnt/c /c
cd /c/repos/col/ghost/isso/docker
./run.sh
```

## Importing
To import comments, add the following to the `isso.conf` file to prevent rate-limiting:

```
[guard]
enabled = false
rateLimit = 2000
```