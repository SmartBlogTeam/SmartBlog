#!/usr/bin/env bash
set -o errexit
if test $(ps h -o comm -p $$) = "sh"; then
    echo "Please use bash to execute this script."
    exit 1
fi

china_install=false
install_name="silverblog"

while getopts "n:c" arg; do
    case ${arg} in
         n)
            install_name=$OPTARG
            ;;
         c)
            china_install=true
            ;;
         ?)
            echo "Unknown argument"
            echo "use ./docker_install.sh [-n <project name> [-t]"
            exit 1
            ;;
    esac
done

docker_image="silverblog/silverblog"
repo_url=https://github.com/SilverBlogTeam/SilverBlog.git

if [ ${china_install} = true ];then
    docker_image="registry.cn-hangzhou.aliyuncs.com/silverblog/silverblog"
    repo_url=https://code.aliyun.com/silverblogteam/silverblog.git
fi

if [ ! -f "initialization.sh" ]; then
    if [ ! -d ${install_name} ]; then
        echo "Cloning silverblog..."
        git clone ${repo_url} --depth=1 ${install_name}
    fi
    cd ${install_name}
    git fetch
    cd install
fi

echo "{\"install\":\"docker\"}" > install.lock

cd ..

if [ ${china_install} = true ]; then
china_option="-c"
fi

if [ ! -f "./nginx_config" ]; then
bash ./nginx_gen.sh -t ${china_option}
fi

bash install/initialization.sh
sed -i '''s/.\/config\/unix_socks\/main.sock/0.0.0.0:5000/g' uwsgi.json
sed -i '''s/.\/config\/unix_socks\/control.sock/0.0.0.0:5001/g' uwsgi.json
if [ ! -f "./docker-compose.yml" ]; then
cat << EOF > docker-compose.yml
version: '3'
services:
  ${install_name}:
    image: "${docker_image}"
    container_name: "${install_name}"
    restart: on-failure:10
    command: python3 watch.py
    volumes:
     - $(pwd):/home/silverblog/
    ports:
     - "127.0.0.1:5000:5000"
  ${install_name}_control:
    image: "${docker_image}"
    container_name: "${install_name}_control"
    restart: on-failure:10
    command: python3 watch.py --control
    volumes:
     - $(pwd):/home/silverblog/
    ports:
     - "127.0.0.1:5001:5001"
EOF
fi

if [ ! -f "./docker-compose-with-nginx.yml" ]; then
cat << EOF > docker-compose-with-nginx.yml
version: '3'
services:
  ${install_name}:
    image: "${docker_image}"
    container_name: "${install_name}"
    restart: on-failure:10
    command: python3 watch.py
    networks:
     - ${install_name}_net
    volumes:
     - $(pwd):/home/silverblog/
  ${install_name}_control:
    image: "${docker_image}"
    container_name: "${install_name}_control"
    restart: on-failure:10
    command: python3 watch.py --control
    networks:
     - ${install_name}_net
    volumes:
     - $(pwd):/home/silverblog/
  ${install_name}_nginx:
    image: "nginx:alpine"
    container_name: "${install_name}_nginx"
    restart: on-failure:10
    command: sh -c "cp \"$(pwd)/nginx_config\" /etc/nginx/conf.d/default.conf && sed -i '''s/127.0.0.1:5000/${install_name}:5000/g' /etc/nginx/conf.d/default.conf && sed -i '''s/127.0.0.1:5001/${install_name}_control:5001/g' /etc/nginx/conf.d/default.conf && nginx -g \"daemon off;\""
    networks:
      - ${install_name}_net
    depends_on:
      - ${install_name}
      - ${install_name}_control
    ports:
      - 80:80
    volumes:
      - $(pwd):$(pwd)
networks:
  ${install_name}_net:
EOF
fi

cat << EOF >manage.sh
#!/usr/bin/env bash
docker run -it --rm -v \$(pwd):/home/silverblog --name="${install_name}_manage" silverblog/silverblog python3 manage.py \$@
EOF
chmod +x manage.sh

echo ""
echo "Before you start SilverBlog for the first time, run the following command to initialize the configuration:"
echo "./manage.sh"
echo ""
echo "You can add the following code to .bashrc to quickly launch SilverBlog."
echo "${install_name}() {(cd \"$(pwd)\"&&./manage.sh \$@)}"
