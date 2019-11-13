#!/bin/sh
mkdir -p /data1/backups/mzj-01 || true
scp -r -C 172.18.197.187:/var/atlassian/application-data/ /data1/backups/mzj-01
scp -r -C 172.18.197.187:/opt/testlink-1.9.13 /data1/backups/mzj-01
