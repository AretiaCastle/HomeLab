# Nextcloud

## Deployment

### TrueNAS Scale App

```text
Nextcloud Configuration
    Timezone: 'Europe/Madrid' timezone
    Postgres Image [default]: Postgres 18
    Admin User: user
    Admin Password: password
    Data Directory Path [default]: /var/www/html/data
    Redis Password: password
    Database Password: password
    PHP Upload Limit (in GB) [default]: 3
    Max Execution Time (in seconds) [default]: 30
    PHP Memory Limit (in MB) [default]: 512
    Op Cache Interned Strings Buffer (in MB) [default]: 32
    Op Cache Memory Consumption (in MB) [default]: 128
Network Configuration
    WebUI Port
        Port Bind Mode [default]: Publish port on the host for external access
        Port Number [default]: 30027
        [Not known how to configure] Certificate ID: 'truenas_default' Certificate
Storage Configuration
    Nextcloud AppData Storage (HTML, Custom Themes, Apps, etc.)
        Type: Host Path
        Host Path: /mnt/main/drive/nextcloud/appdata
    Nextcloud User Data Storage
        Type: Host Path
        Host Path: /mnt/main/drive/nextcloud/userdata
    Nextcloud Postgres Data Storage
        Type: Host Path
        Host Path: /mnt/main/drive/nextcloud/postgres
    Automatic Permissions: TRUE
Resources Configuration
    CPUS: 3
    Memory (in MB): 6146 
```
