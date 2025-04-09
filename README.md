# linux_help


копирование в фоне 
```
nohup rsync -av --progress auto/ art@192.168.31.112:/mnt/ > rsync_status.log 2>&1 &
tail -f rsync_status.log
```