Asi resolvi lo del http3 quiche lsquic todo este problema, resulta que si uno instala quiche u otros tiran por default de las ultimas versiones del protocolo, indagando en la red encontre que hay un software `lsquic` donde tiene muchas flags para debuggear, a esto llegue despues de que vi en wireshark que la conversacion de esto se quedaba en version negotiation y no se recibian mas paquetes. Con lsquic usando las opciones `-l event=debug` y `-l conn=debug` puedes ver trazas del debug de toda la informacion que pasa por ahi, resulta que si tiras de `-o version=h3` como viene por default y recomiendan, la conexion nunca se completa, pero si ves el output del debug te daras cuenta que solo se negocian dos versiones en la respuesta:

```
FF00001B
FF00001D
```

Por lo tanto con los siguientes pasos, yo use el contenedor de docker por mas facilidad, puedes tener el programa http_client y con las flags indicadas abajo puedes usando estas versiones del protocolo; obtener la respuesta del servidor sin problemas:

```bash
cd /opt
git clone https://github.com/litespeedtech/lsquic
cd lsquic
git submodule init
git submodule update
docker build -t lsquic .
docker run -it --rm --name lsquic_container --net=host lsquic http_client -s 127.0.0.1 -H quic.nagini.hogwarts -p / -o version=FF00001D
```
