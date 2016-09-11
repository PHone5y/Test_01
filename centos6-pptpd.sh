!/bin/bash
clear
## Define ##
get_char()
{
SAVEDSTTY=`stty -g`
stty -echo
stty cbreak
dd if=/dev/tty bs=1 count=1 2> /dev/null
stty -raw
stty echo
stty $SAVEDSTTY
}
echo ""
echo -e "\033[47;30m * Press any key to start installing PPTP VPN \033[0m"
echo -e "\033[47;30m * Or press Ctrl+C to cancel the installation \033[0m"
char=`get_char`
echo ""

## Start ##
echo "nameserver 8.8.8.8
nameserver 8.8.4.4
search localdomain" >> /etc/resolv.conf
service network restart

yum remove -y pptpd ppp
iptables --flush POSTROUTING --table nat
iptables --flush FORWARD
rm -rf /etc/pptpd.conf
rm -rf /etc/ppp

arch=`uname -m`
if cat /etc/issue| grep 'OS release 5';then rpm -ivh http://poptop.sourceforge.net/yum/stable/rhel5/pptp-release-current.noarch.rpm;
else
rpm -ivh http://poptop.sourceforge.net/yum/stable/pptp-release-current.noarch.rpm
fi
rpm -ivh http://poptop.sourceforge.net/yum/stable/packages/kernel_ppp_mppe-1.0.2-3dkms.noarch.rpm
yum -y update
yum -y upgrade
yum install -y pptpd ppp dkms
yum -y install make libpcap iptables gcc-c++ logrotate tar cpio perl pam tcp_wrappers policycoreutils

rm -f /dev/ppp
mknod /dev/ppp c 108 0
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "mknod /dev/ppp c 108 0" >> /etc/rc.local
echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/rc.local
echo "localip 10.0.10.1" >> /etc/pptpd.conf
echo "remoteip 10.0.10.2-254" >> /etc/pptpd.conf
echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd
echo "ms-dns 8.8.4.4" >> /etc/ppp/options.pptpd

pass=`98765432109`
if [ "$1" != "" ]
then pass=$1
fi

echo "PHone5y pptpd ${pass} *" >> /etc/ppp/chap-secrets

iptables -t nat -A POSTROUTING -s 10.0.10.0/24 -j MASQUERADE
iptables -A FORWARD -p tcp --syn -s 10.0.10.0/24 -j TCPMSS --set-mss 1356
iptables -I FORWARD -p tcp --syn -i ppp+ -j TCPMSS --set-mss 1356
service iptables save

chkconfig iptables on
chkconfig pptpd on

service iptables start
service pptpd start

## Completed ##
echo ""
echo -e "VPN service is installed, your username is\033[32m PHone5y\033[0m, password is\033[32m ${pass}\033[0m"
echo ""
