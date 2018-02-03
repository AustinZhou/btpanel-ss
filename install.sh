#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
pluginPath=/www/server/panel/plugin/ss

if [ ! -f /etc/init.d/bt ];then
    echo 'No BT-Panel is installed, please go to http://www.bt.cn installation.';
    exit;
fi

Install_ss()
{
    pip install shadowsocks m2crypto
    mkdir -p $pluginPath
    \cp -a -r ss_main.py icon.png info.json index.html install.sh ss.init shadowsocks.zip shadowsocks-nightly-4.2.5.apk $pluginPath/
    \cp -a -r ss.init /etc/init.d/ss
    chmod +x /etc/init.d/ss
    chkconfig --add ss
    chkconfig --level 2345 ss on

    password=`cat /dev/urandom | head -n 16 | md5sum | head -c 16`
    cat > $pluginPath/config.json <<EOF
{
    "server":"0.0.0.0",
    "local_address":"127.0.0.1",
    "local_port":1080,
    "port_password":{
    	"62443":"$password"
    },
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open":false
}
EOF
    groupadd ssuser
    useradd -s /sbin/nologin -M -g ssuser ssuser
    chown ssuser:ssuser $pluginPath/config.json
    Set_port 62443
    /etc/init.d/ss start
}

Set_port()
{
	if [ -f "/usr/sbin/ufw" ];then
		ufw allow $1/tcp
		ufw allow $1/udp
		ufw reload
	fi
	
	if [ -f "/etc/sysconfig/firewalld" ];then
		firewall-cmd --permanent --zone=public --add-port=$1/tcp
		firewall-cmd --permanent --zone=public --add-port=$1/udp
		firewall-cmd --reload
	fi
	
	if [ -f "/etc/init.d/iptables" ];then
		iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport $1 -j ACCEPT
		iptables -I INPUT -p udp -m state --state NEW -m udp --dport $1 -j ACCEPT
		/etc/init.d/iptables save
	fi
}

Remove_port()
{
	if [ -f "/usr/sbin/ufw" ];then
		ufw delete allow $1/tcp
		ufw delete allow $1/udp
		ufw reload
	fi
	
	if [ -f "/etc/sysconfig/firewalld" ];then
		firewall-cmd --permanent --zone=public --remove-port=$1/tcp
		firewall-cmd --permanent --zone=public --remove-port=$1/udp
		firewall-cmd --reload
	fi
	
	if [ -f "/etc/init.d/iptables" ];then
		iptables -D INPUT -p tcp -m state --state NEW -m tcp --dport $1 -j ACCEPT
		iptables -D INPUT -p udp -m state --state NEW -m udp --dport $1 -j ACCEPT
		/etc/init.d/iptables save
	fi
}

Uninstall_ss()
{
    /etc/init.d/ss stop
    chkconfig --del ss
    rm -f /etc/init.d/ss
    rm -rf $pluginPath
    pip uninstall shadowsocks -y
    userdel ssuser
    groupdel ssuser
}

if [ "${1}" == 'install' ];then
	Install_ss
elif [ "${1}" == 'uninstall' ];then
	Uninstall_ss
elif [ "${1}" == 'port' ];then
	Set_port $2
elif [ "${1}" == 'rmport' ];then
	Remove_port $2
else
	while [ "$isInstall" != 'y' ] && [ "$isInstall" != 'n' ]
	do
		read -p "Do you really want to install ss-plugin to BT-Panel?(y/n): " isInstall;
	done
	if [ "$isInstall" = 'y' ] || [ "$isInstall" = 'Y' ];then
		Install_ss
	fi
fi
