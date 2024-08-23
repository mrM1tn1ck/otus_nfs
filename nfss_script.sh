#!/bin/bash

apt install nfs-kernel-server -y
ss -tulpn |grep -e "111" -e "2049"
mkdir -p /srv/share/upload
chown -R nobody:nogroup /srv/share
chmod 0777 /srv/share/upload
touch /srv/share/upload/test_file
cat << EOF > /etc/exports 
/srv/share 192.168.50.11/32(rw,sync,root_squash)
EOF
exportfs -r

echo '##########################'
echo '# PROVISION COMPLETE !!! #'
echo '##########################'