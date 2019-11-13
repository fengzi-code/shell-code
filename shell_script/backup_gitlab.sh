#!/bin/sh
# backup gitlab
# /opt/gitlab/bin/gitlab-rake gitlab:backup:create > /dev/null 2>&1
mkdir -p /data1/backups/mzj-02 || true
scp -r -C 172.18.197.195:/home/apps/gitlab/backups /data1/backups/mzj-02
