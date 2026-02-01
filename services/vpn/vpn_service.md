# VPN Service

## WireGuard

### Instalación Servidor

- [Documentación oficial instalación](https://www.wireguard.com/install/)

```shell
sudo apt install wireguard
```

Habilitar el reenvío de paquetes IP en el sistema operativo:

```shell
sudo nano /etc/sysctl.conf
```

Debe agregarse o descomentarse la siguiente línea:

```text
net.ipv4.ip_forward=1
```

Una vez instalado WireGuard instalaremos WGDashboard para poder realizar la
gestión y configuración desde una interfaz web

### Instalación Cliente

#### Linux

- [Documentación oficial instalación](https://www.wireguard.com/install/)

Primero creamos las claves públicas y privadas a utilizar y configuramos la
interfaz. En el ejemplo la interfaz tiene de nombre `wg0` pero puede utilizarse
el nombre que se quiera.

```shell
sudo wg genkey | sudo tee /etc/wireguard/"$HOSTNAME"_private.key 
sudo cat /etc/wireguard/"$HOSTNAME"_private.key | wg pubkey | sudo tee /etc/wireguard/"$HOSTNAME"_public.key
```

```shell
sudo nano /etc/wireguard/wg0.conf
```

La información a incluir en el documento tiene el siguiente formato. Complete con los parámetros adecuados para su caso.

```text
[Interface]
PrivateKey = <clave privada del cliente>
Address = 10.0.0.1/32
MTU = 1420
DNS = 8.8.8.8

[Peer]
PublicKey = <clave pública servidor>
AllowedIPs = 0.0.0.0/0
Endpoint = name.exmaple:51820
PersistentKeepalive = 21
```

Una vez configurada la conexión con la VPN se puede establecer con el siguiente comando:

```shell
sudo wg-quick up wg0
```

La conexión se puede cerrar con el siguiente comando

```shell
sudo wg-quick down wg0
```

#### Android

## WGDashboard

- [Sitio oficial](https://docs.wgdashboard.dev/)

### Instalación

- [Documentación oficial instalación](https://docs.wgdashboard.dev/install/)

```shell
sudo apt-get install git iptables -y && \
sudo apt-get update && \
sudo apt install wireguard-tools net-tools && \
git clone https://github.com/donaldzou/WGDashboard.git && \
cd ./WGDashboard/src && \
chmod +x ./wgd.sh && \
./wgd.sh install
```

Tras la instalación para arranque el servicio:

```shell
cd ./WGDashboard/src && ./wgd.sh start
```

Una vez que el servicio esté listo, puedes acceder a la interfaz de
administración en `http://localhost:10086/`. El usuario por defecto es `admin`
y la contraseña por defecto es `admin`.

### Configuración

- [Documentación oficial configuración](https://docs.wgdashboard.dev/guides/Add-WireGuard-Configuration.html)

Asignar a los clientes de la VPN direcciones de la propia red interna puede
llevar a errores por lo que es recomendable utilizar para estos clientes un
rango de direcciones privado fuera del que maneja el router o la red a la que se
accede. Además es posible que el router encargado de la red no permite el
tráfico de paquetes con destino una IP privada fuera del rango de su red. Por
estás dos razones puede ser necesario configurar un NAT en la máquina que aloja
el servicio de VPN.

Se requiere realizar una configuración en los campos `PostUp` y `PostDown` del
servicio incluyendo lo siguiente en cada caso. Recuerda cambiar
`INTERFACE_NAME` por el nombre de la interfaz por la que se va a dirigir el
tráfico.

- Campo `PostUp`

```shell
iptables -A FORWARD -i VPN -j ACCEPT; iptables -t nat -A POSTROUTING -o INTERFACE_NAME -j MASQUERADE
```

- Campo `PostDown`

```shell
iptables -D FORWARD -i VPN -j ACCEPT; iptables -t nat -D POSTROUTING -o INTERFACE_NAME -j MASQUERADE
```

### Actualización

Para actualizar el servicio debemos ejecutar otra vez el script de instalación,
aunque antes es recomendable actualizar el repositorio local.

```shell
git clone https://github.com/donaldzou/WGDashboard.git && \
cd ./WGDashboard/src && \
chmod +x ./wgd.sh && \
./wgd.sh install && \
```

## Reinicio de contraseña

- [Instrucciones oficiales](https://docs.wgdashboard.dev/reset-wgdashboard-password.html)
