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

## Azure File Share and SQLite
To get sqlite to work on a File share, you must enable WAL mode. Create the db, then run this command:

```
sqlite3 the.db 'PRAGMA journal_mode=wal;'
```

Then copy the db to the file share.