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

## MySQL
Spin up a MySQL container like so:
```
docker run --name mysql -e MYSQL_ROOT_PASSWORD=S0m3L0ngP@ssw0rd -e MYSQL_USER=isso -e MYSQL_PASSWORD=S0m3L0ngP@ssw0rd -e MYSQL_DATABASE=comments -d -p 3306:3306 mysql:latest
```

Update the config to specify mysql.

## Azure File Share and SQLite
> **Note:** This does not work!

To get sqlite to work on a File share, you must enable WAL mode. Create the db, then run this command:

```
sqlite3 the.db 'PRAGMA journal_mode=wal;'
```

Then copy the db to the file share.