#!/usr/bin/env bash
set -o errexit

bash /home/silverblog/install/initialization.sh
sed -i '''s/.\/config\/unix_socks\/main.sock/0.0.0.0:5000/g' uwsgi.json
sed -i '''s/.\/config\/unix_socks\/control.sock/0.0.0.0:5001/g' uwsgi.json
cp -f /home/silverblog/.develop/demo/page.json /home/silverblog/config/page.json
cp -f /home/silverblog/.develop/demo/menu.json /home/silverblog/config/menu.json
cp -f /home/silverblog/.develop/demo/system.json /home/silverblog/config/system.json
cp /home/silverblog/.develop/demo/demo-article.md /home/silverblog/document/demo-article.md
python3 manage.py update
cd /home/silverblog/templates
bash -c "$(curl -fsSL https://raw.githubusercontent.com/SilverBlogTheme/clearision/master/install.sh)"
cd /home/silverblog/
cat << EOF >supervisor.conf
[supervisord]
nodaemon=true

[program:nginx]
command=/usr/sbin/nginx -g "daemon off;"
stdout_logfile=/var/log/nginx.stdout.log
stderr_logfile=/var/log/nginx.stderr.log

[program:main]
command=/home/silverblog/watch.py
autorestart=true
stdout_logfile=/var/log/silverblog-main.stdout.log
stderr_logfile=/var/log/silverblog-main.stderr.log

[program:control]
command=/home/silverblog/watch.py --control
autorestart=true
stdout_logfile=/var/log/silverblog-control.stdout.log
stderr_logfile=/var/log/silverblog-control.stderr.log
EOF