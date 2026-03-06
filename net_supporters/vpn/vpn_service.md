# VPN Service

## WireGuard

### Deployment

#### Bare-metal deployment

- [Documentación oficial instalación](https://www.wireguard.com/install/)

```shell
sudo apt install wireguard
```

Enable IP packet forwarding in the operating system:

```shell
sudo sed 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf
```

Once wireguard is installed we will deploy WGDashboard to manage and configure the VPN from a web interface.

## WGDashboard

- [Official website](https://docs.wgdashboard.dev/)

### Deployment

#### Bare-metal deployment

- [Official installation documentation](https://docs.wgdashboard.dev/install/)

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

[!TODO] Además configuramos el arranque automático del servicio:

```shell
echo "Arranque automático del servicio WGDashboard"
```

Una vez que el servicio esté listo, puedes acceder a la interfaz de
administración en `http://localhost:10086/`. El usuario por defecto es `admin`
y la contraseña por defecto es `admin`.

### Configuración

- [Official configuration guide](https://docs.wgdashboard.dev/guides/Add-WireGuard-Configuration.html)

Assigning VPN clients addresses from the internal network can lead to errors, so
it is recommended to use a private address range for these clients outside of
the one managed by the router or the network being accessed. Additionally, it is
possible that the router in charge of the network does not allow traffic of
packets destined for a private IP outside of its network range. For these two
reasons, it may be necessary to configure NAT on the machine hosting the VPN
service.

It is necessary to perform a configuration in the `PostUp` and `PostDown` fields
of the service including the following in each case. Remember to change
`INTERFACE_NAME` by the name of the interface through which the traffic will be
directed.

Field `PostUp`, substitute the fields `PREFIX`, `VPN_NAME`, `MAIN_INTERFACE`.

```shell
iptables -A FORWARD -s <PREFIX> -i <VPN_NAME> -o <MAIN_INTERFACE> -j ACCEPT && iptables -A FORWARD -d <PREFIX> -i <MAIN_INTERFACE> -o <VPN_NAME> -m state --state RELATED,ESTABLISHED -j ACCEPT && iptables -t nat -A POSTROUTING -s <PREFIX> -o <MAIN_INTERFACE> -j MASQUERADE
```

Execute this command to copy and paste the configuration:

```shell
PREFIX="10.0.0.0/24"
VPN_NAME="Aretia"
MAIN_INTERFACE="eth0"
echo ''
echo "iptables -A FORWARD -s $PREFIX -i $VPN_NAME -o $MAIN_INTERFACE -j ACCEPT && iptables -A FORWARD -d $PREFIX -i $MAIN_INTERFACE -o $VPN_NAME -m state --state RELATED,ESTABLISHED -j ACCEPT && iptables -t nat -A POSTROUTING -s $PREFIX -o $MAIN_INTERFACE -j MASQUERADE"
echo ''
```

Field `PostDown`, substitute the fields `PREFIX`, `VPN_NAME`, `MAIN_INTERFACE`

```shell
iptables -D FORWARD -s <PREFIX> -i <VPN_NAME> -o <MAIN_INTERFACE> -j ACCEPT && iptables -D FORWARD -d <PREFIX> -i <MAIN_INTERFACE> -o <VPN_NAME> -m state --state RELATED,ESTABLISHED -j ACCEPT && iptables -t nat -D POSTROUTING -s <PREFIX> -o <MAIN_INTERFACE> -j MASQUERADE
```

Execute this command to copy and paste the configuration:

```shell
PREFIX="10.0.0.0/24"
VPN_NAME="Aretia"
MAIN_INTERFACE="eth0"
echo ''
echo "iptables -D FORWARD -s $PREFIX -i $VPN_NAME -o $MAIN_INTERFACE -j ACCEPT && iptables -D FORWARD -d $PREFIX -i $MAIN_INTERFACE -o $VPN_NAME -m state --state RELATED,ESTABLISHED -j ACCEPT && iptables -t nat -D POSTROUTING -s $PREFIX -o $MAIN_INTERFACE -j MASQUERADE"
echo ''
```

### Actualización

To update the service we must run the installation script again, although before
it is recommended to update the local repository.

```shell
git clone https://github.com/donaldzou/WGDashboard.git && \
cd ./WGDashboard/src && \
chmod +x ./wgd.sh && \
./wgd.sh install && \
```

## Reinicio de contraseña

- [Official instructions](https://docs.wgdashboard.dev/reset-wgdashboard-password.html)
