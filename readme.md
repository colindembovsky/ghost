# Convert from Colin's ALM Corner MiniBlog to Ghost
Repo for converting posts from MiniBlog to Ghost

## Creating Docker Image
```
$key="<az storage key>"
docker build . -t col/ghost
docker run -d --name ghost -e url=http://localhost:3001 -e AZURE_STORAGE_CONNECTION_STRING=$key -p 3001:2368 col/ghost:latest
```

## Upload image files
```
$key="<az storage key>"
az storage blob upload-batch --connection-string $key -d ghostcontent --destination-path images/files -s ../files/
```

## Import posts
```
# download posts from old storage account to folder 'exported'
yarn install
yarn go
```

This creates `import.json`. Navigate to ghost/labs page and import this file.