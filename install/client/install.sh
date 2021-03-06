#!/bin/bash
#
set -e
cd "$( dirname "$0"  )"
cur_dir=$(pwd)
work_dir=/var/opt/monster/client
# 安装依赖包
os=$(cat /proc/version)
if (echo $os|grep centos) || (echo $os|grep 'Red Hat')
then
    yum makecache fast
    yum install -y epel-release
    yum install -y gcc smartmontools dmidecode python-pip python-devel  libselinux-python dos2unix
elif (echo $os|grep Ubuntu)
then
    apt-get update
    apt-get install -y gcc smartmontools dmidecode python-pip python-dev tofrodos
    sed -i "s/PermitRootLogin/\#PermitRootLogin/g" /etc/ssh/sshd_config
    service ssh restart
else
    echo "your os version is not supported!"
fi


echo "####install pip mirror####"
mkdir -p  ~/.pip
cat <<EOF > ~/.pip/pip.conf
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/

[install]
trusted-host=mirrors.aliyun.com
EOF

echo "####install pip packages####"
mkdir -p $work_dir

source /etc/profile

echo "####config monster agent####"
if (echo $os|grep centos) || (echo $os|grep 'Red Hat')
then
    if (rpm -ql python|grep 2.6)
    then
        pip install -U pip==9.0.3
        pip install virtualenv==14.0.0
        pip install setuptools==28.5.0
        scp $cur_dir/monster_agent.py $work_dir
        scp $cur_dir/uninstall.sh $work_dir
        scp $cur_dir/monster /etc/init.d/
        dos2unix $work_dir/monster_agent.py
        dos2unix /etc/init.d/monster
        chmod +x /etc/init.d/monster
    else
        pip install -U pip==19.0.3
        pip install virtualenv==15.2.0
        scp $cur_dir/monster_agent.py $work_dir
        scp $cur_dir/uninstall.sh $work_dir
        scp $cur_dir/monster.service /usr/lib/systemd/system/
        dos2unix $work_dir/monster_agent.py
        dos2unix /usr/lib/systemd/system/monster.service
        systemctl daemon-reload
    fi
    chkconfig monster on
elif (echo $os|grep Ubuntu)
then
    pip install -U pip==19.0.3
    pip install virtualenv==15.2.0
    scp $cur_dir/monster_agent.py $work_dir
    scp $cur_dir/uninstall.sh $work_dir
    scp $cur_dir/monster.service /etc/systemd/system/
    fromdos $work_dir/monster_agent.py
    fromdos /etc/systemd/system/monster.service
    systemctl daemon-reload
    systemctl enable monster
else
    echo "your os version is not supported!"
fi

cd $work_dir
virtualenv venv
source $work_dir/venv/bin/activate
#pip install python-daemon==2.1.2
pip install requests==2.11.1
pip install psutil==5.2.2
pip install schedule==0.4.3

echo "####client prepare finished!###"
#ubuntu_version=`cat /proc/version|grep 16.04`
#if [ "$ubuntu_version" ]
#then
#    systemctl daemon-reload
#fi
systemctl start monster.service
echo "####client install finished!###"
echo "please using <systemctl start|restart|stop monster.service> manage monster agent"
