### OTUS Linux Professional Lesson #9

#### ЦЕЛЬ:
Знакомство с файловой системой NFS
#### ОПИСАНИЕ ДОМАШНЕГО ЗАДАНИЯ:
Основная часть: 
* vagrant up должен поднимать 2 настроенных виртуальных машины (сервер NFS и клиента) без дополнительных ручных действий;
на сервере NFS должна быть подготовлена и экспортирована директория; 
* в экспортированной директории должна быть поддиректория с именем upload с правами на запись в неё; 
экспортированная директория должна автоматически монтироваться на клиенте при старте виртуальной машины (systemd, autofs или fstab — любым способом);
* монтирование и работа NFS на клиенте должна быть организована с использованием NFSv3.
Для самостоятельной реализации: 
* настроить аутентификацию через KERBEROS с использованием NFSv4.


>[!TIP]
>При развертывании стенда, используя __Vagrantfile__, на сервере запускается скрипт __nfss_script.sh__, а на клиенте - __nfsс_script.sh__. После чего выполнятся действия описаные ниже, то есть будет настроен nfs сервер и nfs клиент.

#### ВЫПОЛНЕНИЕ:
1. Поднимаем с помощью Vagrantfile две виртуальные машины: __nfss__ - сервер NFS, __nfsc__ - клиент NFS
   
2. Настраиваем NFS сервер:
   
Установим сервер NFS:
```
apt install nfs-kernel-server
```
Запускаем сервер NFS:
```
systemctl enable nfs-kernel-server --now
```

Проверяем наличие слушающих портов 2049/udp, 2049/tcp, 111/udp, 111/tcp 
```
ss -tulpn |grep -e "111" -e "2049"
```
Создаем и настриваем директорию, которая будет экспортирована в будущем:
```
mkdir -p /srv/share/upload
chown -R nfsnobody:nfsnobody /srv/share
chmod 0777 /srv/share/upload
```
Добавляем запись в /etc/exports:
```
cat << EOF > /etc/exports
/srv/share 192.168.50.11/32(rw,sync,root_squash)
EOF
```
Экспортируем только что созданную директорию:
```
[root@nfss ~]# exportfs -r
```
Проверяем:
```
[root@nfss ~]# exportfs -s
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```
3. Настраиваем клиент NFSC:
Установим пакет с NFS-клиентом:
```
sudo apt install nfs-common
```
Добавляем в __/etc/fstab__ строку:
```
echo "192.168.50.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
```
Выполняем:
```
systemctl daemon-reload
systemctl restart remote-fs.target
```
>[!NOTE]
>Перечитывать конфигурацию systemd нужно потому что systemd обрабатывает файл fstab, чтобы создать модули для монтирования устройств. Такие модули находятся во временной директории /run.
>В данном случае происходит автоматическая генерация systemd units в каталоге `/run/systemd/generator/`, которые производят монтирование при первом обращении к каталогу `/mnt/`

Заходим в директорию `/mnt/` и проверяем успешность монтирования
```
[root@nfsc mnt]# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=30,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=10737)
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
```
Для того чтобы посмотреть на сервере кем промонтированны шары выполняем:
```
[root@nfss ~]# showmount -a
```