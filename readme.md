# dockerbox

A basic system for managing multiple docker stacks that I started working on. I've since migrated away from this older version to a newer verison that deploys using swarm - I'm working on cleaning that up for publishing on GH too - thus this is in a very much half finished state.

## Service Overview

Each service is contained within its own directory, the folder structure should look something like this:

```bash
/service
|-- docker-compose.yml
|-- backup
|   |-- main
|-- volumes
|   |-- app_data
|   |-- db_data
```

The `docker-compose.yml` contains each applications services, for example you may have containers for 'nginx', `mariadb` and `php` as part of a LEMP stack.

The `volumes` directory should be used for any local bind mounts you want, for example `volumes/app_data` and `volumes/db_data` could be used to hold your LEMP stack's app and database data respectivly.

The `backup` directory is used to hold backups generated by `dockerbox.sh`.

## Supported Services

### Dash (Dashy)

*"A self-hostable personal dashboard built for you. Includes status-checking, widgets, themes, icon packs, a UI editor and tons more!"*

### Grafana

### InfluxDB

*"InfluxDB is an open source time series database for recording metrics, events, and analytics."*

#### Interacting with the `influx` cli tool

You can use `docker exec` to interact with the [`influx` cli tool](https://docs.influxdata.com/influxdb/cloud/reference/cli/influx/#commands)

For example to change the password for the admin users:

`docker exec influxdb influx user password -n admin -t my-super-secret-auth-token`

Note the `my-super-secret-auth-token` should match the value you specified for `DOCKER_INFLUXDB_INIT_ADMIN_TOKEN` during setup.

### Kuma (UptimeKuma)
### Labstact (Bookstack)
### npm (Nginx Proxy Manager)

