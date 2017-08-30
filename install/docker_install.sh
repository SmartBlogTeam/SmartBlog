#!/usr/bin/env bash
cd ..

echo "Generate a Nginx configuration file..."

x=$(pwd)

cat << EOF >nginx_config
server {
    listen 80;
    location / {
        include uwsgi_params;
        uwsgi_pass 127.0.0.1:5000;
    }
    location /control {
        add_header 'Access-Control-Allow-Origin' 'https://silverblog.org';
        include uwsgi_params;
        uwsgi_pass 127.0.0.1:5001;
    }
    location /static {
        alias $x/templates/static;
    }
}
EOF

echo "Create directory..."

mkdir ./document
mkdir ./templates
mkdir ./templates/static
mkdir ./config

echo "Create configuration file..."

cp -i ./example/menu.example.json ./config/menu.json
cp -i ./example/page.example.json ./config/page.json
cp -i ./example/system.example.json ./config/system.json

cp -i ./example/start.example.json ./start.json
cp -i ./example/uwsgi.example.json ./uwsgi.json

cat << EOF >./start.sh
#!/usr/bin/env bash
docker run -t -i -v $(pwd):/home/SilverBlog -p 5000:5000 silverblog uwsgi --json /home/SilverBlog/uwsgi.json
EOF
cat << EOF >./control-start.sh
#!/usr/bin/env bash
docker run -t -i -v $(pwd):/home/SilverBlog -p 5000:5000 silverblog uwsgi --json /home/SilverBlog/uwsgi.json:control
EOF

chmod +x manage.py

echo "The installation is complete! Please edit $x/config/system.json file."