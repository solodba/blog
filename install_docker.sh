#!/bin/bash
# centos 7简单安装Docker服务
 
# 关闭防火墙
stop_firewall(){
	echo ""
	echo ""
	echo "#########################################################"
	echo "# Step1：关闭防火墙 -- 开始                              #"
	echo "#########################################################"
	iptables -F
	systemctl stop firewalld.service
	systemctl disable firewalld.service
	echo "#########################################################"
	echo "# Step1：关闭防火墙 -- 结束                              #"
	echo "#########################################################"
}

# 关闭selinux
stop_selinux(){
	echo ""
	echo ""
	echo "#########################################################"
	echo "# Step2：关闭selinux -- 开始                             #"
	echo "#########################################################"
	sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config
	setenforce 0
	echo "#########################################################"
	echo "# Step2：关闭selinux -- 结束                             #"
	echo "#########################################################"
}

# 配置阿里yum源
aliyum_config(){
	echo ""
	echo ""
	echo "#########################################################"
	echo "# Step3：配置阿里yum源 -- 开始                           #"
	echo "#########################################################"
	yum -y install wget
	cd /etc/yum.repos.d/
	rm -fr *.repo
	wget http://mirrors.aliyun.com/repo/Centos-7.repo
	yum clean all
	yum makecache
	yum repolist
	echo "#########################################################"
	echo "# Step3：配置阿里yum源 -- 结束                           #"
	echo "#########################################################"
}


# 删除docker老版本
del_oldver(){
	echo ""
	echo ""
	echo "#########################################################"
	echo "# Step4：删除docker老版本 -- 开始                        #"
	echo "#########################################################"
	yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
	echo "#########################################################"
	echo "# Step4：删除docker老版本 -- 结束                        #"
	echo "#########################################################"
}

# 为yum配置docker仓库
yum_docker_repository(){
	echo ""
	echo ""
	echo "#########################################################"
	echo "# Step5：为yum配置docker仓库 -- 开始                     #"
	echo "#########################################################"
	yum install -y yum-utils
	yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	echo "#########################################################"
	echo "# Step5：为yum配置docker仓库 -- 结束                     #"
	echo "#########################################################"
}
 
# 安装最新docker
install_docker(){
	echo ""
	echo ""
	echo "#########################################################"
	echo "# Step6：安装最新docker -- 开始                          #"
	echo "#########################################################"
	yum install -y docker-ce docker-ce-cli containerd.io
	echo "#########################################################"
	echo "# Step6：安装最新docker -- 结束                          #"
	echo "#########################################################"
}

# 启动并加入开机启动
add_docker_start(){
	echo ""
	echo ""
	echo "#########################################################"
	echo "# Step7：启动并加入开机启动 -- 开始                       #"
	echo "#########################################################"
	systemctl start docker
	systemctl enable docker
	echo "#########################################################"
	echo "# Step7：启动并加入开机启动 -- 结束                       #"
	echo "#########################################################"
}

# 验证安装是否成功
check_install(){
	echo ""
	echo ""
	echo "#########################################################"
	echo "# Step8：验证安装是否成功 -- 开始                         #"
	echo "#########################################################"
	docker version
	echo "#########################################################"
	echo "# Step8：验证安装是否成功 -- 结束                         #"
	echo "#########################################################"
}

# 添加docker国内镜像站点并重启docker
add_docker_site(){
	echo ""
	echo ""
	echo "#########################################################"
	echo "# Step9：添加 docker 国内镜像站点并重启docker -- 开始     #"
	echo "#########################################################"
	mkdir -p /etc/docker
	echo '{ "registry-mirrors": [ "https://b9pmyelo.mirror.aliyuncs.com" ] }' >> /etc/docker/daemon.json
	systemctl restart docker
	echo "#########################################################"
	echo "# Step9：添加 docker 国内镜像站点并重启docker -- 结束     #"
	echo "#########################################################"
	echo ""
	echo "" 
}

# 安装步骤
install_step(){
	stop_firewall
	stop_selinux
	aliyum_config
	del_oldver
	yum_docker_repository
	install_docker
	add_docker_start
	check_install
	add_docker_site	
}

# docker安装
echo "#########################################################"
echo "# docker安装 -- 开始                                    #"
echo "#########################################################"
install_step
echo "#########################################################"
echo "# docker安装 -- 结束                                    #"
echo "#########################################################"