#!/bash/bin

# 定义家目录
homedir=$PWD

# 检查Docker服务是否开启
check_docker(){
status=`systemctl status docker | grep -i 'Active' | awk -F ':' '{print $2}' | awk '{print $1}'`
if [ "$status" = "active" ];then
    echo -e "#########################################################"
    echo -e "#####################Docker服务已经开启！################"
    echo -e "#########################################################\n"
else
    echo -e "#########################################################"
    echo -e "###########Docker服务已经停止！退出安装！################"
    echo -e "#########################################################\n" 
    exit 0
fi
}

# 检查Nginx容器所需包和清单文件是否存在
check_nginx_pkg(){
  if [ ! -f $homedir/nginx_swl.conf ];then
      echo -e "#########################################################"
      echo -e "####安装所需清单文件nginx_swl.conf不存在！退出安装！####"
      echo -e "#########################################################\n"
      exit 0
  else
      echo -e "#########################################################"
      echo -e "###############安装所需清单文件nginx_swl.conf存在!##########"
      echo -e "#########################################################\n"
  fi
  
 while read line
  do
    name=`echo $line | awk '{print $1'}`
    if [ ! -f $homedir/$name ];then
      echo -e "#########################################################"
      echo -e "###$homedir/$name文件不存在!退出安装!###"
      echo -e "#########################################################\n"
      exit 0
    else
      echo -e "#########################################################"
      echo -e "###$homedir/$name文件存在!###"
      echo -e "#########################################################\n"
    fi
  done < $homedir/nginx_swl.conf
}

# 创建Nginx容器的Dockerfile文件
create_nginx_dockerfile(){
cat > $homedir/Dockerfile_nginx << "EOF"
FROM centos:7
LABEL maintainer code-horse
RUN yum install -y gcc gcc-c++ make \
    openssl-devel pcre-devel gd-devel \
    iproute net-tools telnet wget curl && \
    yum clean all && \
    rm -rf /var/cache/yum/*

ADD nginx-1.15.5.tar.gz /
RUN cd nginx-1.15.5 && \
    ./configure --prefix=/usr/local/nginx \
    --with-http_ssl_module \
    --with-http_stub_status_module && \
    make -j 4 && make install && \
    mkdir /usr/local/nginx/conf/vhost && \
    cd / && rm -rf nginx* && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV PATH $PATH:/usr/local/nginx/sbin
COPY nginx.conf /usr/local/nginx/conf/nginx.conf
WORKDIR /usr/local/nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# 判断文件是否创建成功
if [ -f $homedir/Dockerfile_nginx ];then
  echo -e "#########################################################"
  echo -e "###################Dockerfile_nginx文件创建成功！#########"
  echo -e "#########################################################\n"
else
  echo -e "#########################################################"
  echo -e "###################Dockerfile_nginx文件创建失败！#########"
  echo -e "#########################################################\n"
  exit 0
fi
}

# 创建Nginx镜像文件
create_nginx_image(){
  docker image build -t nginx:v1 -f $homedir/Dockerfile_nginx $homedir/
  result=$?
  repository=`docker image ls | grep 'nginx' | awk '{print $1}'`
  tag=`docker image ls | grep 'nginx' | awk '{print $2}'`
  if [ $result -eq 0 -a "$repository"="nginx" -a "$tag"="v1" ];then
    echo -e "#########################################################"
    echo -e "###################Nginx镜像文件创建成功!################"
    echo -e "#########################################################\n"
  else
    echo -e "#########################################################"
    echo -e "###################Nginx镜像文件创建失败!################"
    echo -e "#########################################################\n"
    exit 0
  fi
}

# 通过Nginx镜像文件创建容器
create_nginx_docker(){
 docker run -d --name lnmp_nginx \
 --net lnmp \
 -p 88:80 \
 --mount src=wwwroot,dst=/wwwroot \
 --mount type=bind,src=$PWD/php.conf,dst=/usr/local/nginx/conf/vhost/php.conf nginx:v1
 result=$?
 cnt=`docker container ls -a | grep lnmp_nginx | wc -l`
 if [ $result -eq 0 -a $cnt -eq 1 ];then
    echo -e "#########################################################"
    echo -e "#####################Nginx容器创建成功!##################"
    echo -e "#########################################################\n"
 else
    echo -e "#########################################################"
    echo -e "#####################Nginx容器创建失败!##################"
    echo -e "#########################################################\n"
    exit 0
 fi  
}

# 检查php所需包和清单文件是否存在
check_php_pkg(){
  if [ ! -f $homedir/php_swl.conf ];then
      echo -e "#########################################################"
      echo -e "####安装所需清单文件php_swl.conf不存在！退出安装！####"
      echo -e "#########################################################\n"
      exit 0
  else
      echo -e "#########################################################"
      echo -e "###############安装所需清单文件php_swl.conf存在!###########"
      echo -e "#########################################################\n"
  fi
  
 while read line
  do
    name=`echo $line | awk '{print $1'}`
    if [ ! -f $homedir/$name ];then
      echo -e "#########################################################"
      echo -e "###$homedir/$name文件不存在!退出安装!###"
      echo -e "#########################################################\n"
      exit 0
    else
      echo -e "#########################################################"
      echo -e "###$homedir/$name文件存在!###"
      echo -e "#########################################################\n"
    fi
  done < $homedir/php_swl.conf
}

# 创建php容器的Dockerfile文件
create_php_dockerfile(){
cat > $homedir/Dockerfile_php << "EOF"
FROM centos:7
LABEL MAINTAINER code-horse
RUN yum install epel-release -y && \
    yum install -y gcc gcc-c++ make gd-devel libxml2-devel \
    libcurl-devel libjpeg-devel libpng-devel openssl-devel \
    libmcrypt-devel libxslt-devel libtidy-devel autoconf \
    iproute net-tools telnet wget curl && \
    yum clean all && \
    rm -rf /var/cache/yum/*

ADD php-5.6.36.tar.gz /
RUN cd php-5.6.36 && \
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --enable-fpm --enable-opcache \
    --with-mysql --with-mysqli --with-pdo-mysql \
    --with-openssl --with-zlib --with-curl --with-gd \
    --with-jpeg-dir --with-png-dir --with-freetype-dir \
    --enable-mbstring --with-mcrypt --enable-hash && \
    make -j 4 && make install && \
    cp php.ini-production /usr/local/php/etc/php.ini && \
    cp sapi/fpm/php-fpm.conf /usr/local/php/etc/php-fpm.conf && \
    sed -i "90a \daemonize = no" /usr/local/php/etc/php-fpm.conf && \
    mkdir /usr/local/php/log && \
    cd / && rm -rf php* && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV PATH $PATH:/usr/local/php/sbin
COPY php.ini /usr/local/php/etc/
COPY php-fpm.conf /usr/local/php/etc/
WORKDIR /usr/local/php
EXPOSE 9000
CMD ["php-fpm"]
EOF

# 判断文件是否创建成功
if [ -f $homedir/Dockerfile_php ];then
  echo -e "#########################################################"
  echo -e "###################Dockerfile_php文件创建成功！##############"
  echo -e "#########################################################\n"
else
  echo -e "#########################################################"
  echo -e "###################Dockerfile_php文件创建失败！##############"
  echo -e "#########################################################\n"
  exit 0
fi
}

# 创建php镜像文件
create_php_image(){
  docker image build -t php:v1 -f $homedir/Dockerfile_php $homedir/
  result=$?
  repository=`docker image ls | grep 'php' | awk '{print $1}'`
  tag=`docker image ls | grep 'php' | awk '{print $2}'`
  if [ $result -eq 0 -a "$repository"="php" -a "$tag"="v1" ];then
    echo -e "#########################################################"
    echo -e "###################php镜像文件创建成功!################"
    echo -e "#########################################################\n"
  else
    echo -e "#########################################################"
    echo -e "###################php镜像文件创建失败!################"
    echo -e "#########################################################\n"
    exit 0
  fi
}

# 通过php镜像文件创建容器
create_php_docker(){
 docker run -d --name lnmp_php \
 --net lnmp \
 --mount src=wwwroot,dst=/wwwroot php:v1
 result=$?
 cnt=`docker container ls -a | grep lnmp_php | wc -l`
 if [ $result -eq 0 -a $cnt -eq 1 ];then
    echo -e "#########################################################"
    echo -e "#####################php容器创建成功!##################"
    echo -e "#########################################################\n"
 else
    echo -e "#########################################################"
    echo -e "#####################php容器创建失败!##################"
    echo -e "#########################################################\n"
    exit 0
 fi  
}

# 创建Docker存储网络
create_network(){
  docker network create lnmp
  result=$?
  name=`docker network ls | grep 'lnmp' | awk '{print $2}'`
  if [ $result -eq 0 -a "$name"="lnmp" ];then
    echo -e "#########################################################"
    echo -e "#####################容器网络创建成功！###################"
    echo -e "#########################################################\n"
  else
    echo -e "#########################################################"
    echo -e "#####################容器网络创建失败！###################"
    echo -e "#########################################################\n"
    exit 0
  fi    
}

# 创建MySQL5.7容器
create_mysql(){
  docker run -d --name lnmp_mysql --net lnmp \
  --mount src=mysql-vol,dst=/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=123456 -e MYSQL_DATABASE=wordpress mysql:5.7 \
  --character-set-server=utf8
  result=$?
  cnt=`docker container ls | grep 'mysql' | wc -l`
  if [ $result -eq 0 -a $cnt -eq 1 ];then
    echo -e "#########################################################"
    echo -e "#################mysql5.7容器安装成功！###################"
    echo -e "#########################################################\n"
  else
    echo -e "#########################################################"
    echo -e "#################mysql5.7容器安装失败！###################"
    echo -e "#########################################################\n"
    exit 0
  fi  
}

# 创建Nginx容器
install_nginx_docker(){
   echo -e "#########################################################"
   echo -e "###################Nginx容器开始生成!#####################"
   echo -e "#########################################################\n"
   check_docker
   check_nginx_pkg
   create_nginx_dockerfile
   create_nginx_image
   create_nginx_docker
   echo -e "#########################################################"
   echo -e "###################Nginx容器结束生成!#####################"
   echo -e "#########################################################\n"   
}

# 创建php容器
install_php_docker(){
   echo -e "#########################################################"
   echo -e "###################php容器开始生成!#####################"
   echo -e "#########################################################\n"
   check_docker
   check_php_pkg
   create_php_dockerfile
   create_php_image
   create_php_docker
   echo -e "#########################################################"
   echo -e "###################php容器结束生成!#####################"
   echo -e "#########################################################\n"     
}

# 搭建个人博客网站
install_web_blog(){
  echo -e "#########################################################"
  echo -e "#####################个人博客网站生成开始!##################"
  echo -e "#########################################################\n"
  # 创建Docker存储网络
  create_network
  # 创建mysql容器
  create_mysql
  # 创建php容器
  install_php_docker
  # 创建Nginx容器
  install_nginx_docker
  echo -e "#########################################################"
  echo -e "#####################个人博客网站生成结束!##################"
  echo -e "#########################################################\n"
}

# 个人博客网站搭建
install_web_blog