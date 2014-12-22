userdel -r jenkins
groupdel devs

groupadd devs
#useradd -D -b /export/home
useradd -g devs -s /usr/bin/bash -m jenkins
#required group for virtualbox to allow access to shared folder
usermod -G vboxsf jenkins
echo 'Password: J3nkins'
passwd jenkins
