# Public dynamic DNS Service

In order to access services hosted in a home lab from the internet, it is often
necessary to have a domain name that points to the public IP address of the home
network. This service provides a way to automatically update a DNS record with the
current public IP address of the home network, allowing users to access their
services using a consistent domain name.

## DuckDNS

- [Official Site](https://www.duckdns.org/)

### Installation

Installation via linux cron. For this you need fisrt cron and curl installed.
Test it with:

```bash
ps -ef | grep cr[o]n
```

```bash
curl --version
```

Now lets install it:

```bash
mkdir duckdns
cd duckdns
vi duck.sh
```

Copy and paste the following code into `duck.sh`, replacing `your-domain`
and `your-token` with your actual DuckDNS domain and token:

```bash
echo url="https://www.duckdns.org/update?domains=your-domain&token=your-token&ip=" | curl -k -o ~/duckdns/duck.log -K -
```

Make the script executable:

```bash
chmod 700 duck.sh
```

Edit your crontab to run the script every 5 minutes:

```bash
crontab -e
```

Add the following line to the crontab file:

```text
*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1
```

Execute the script once to verify it works:

```bash
~/duckdns/duck.sh
```

Check the log file to see if the update was successful:

```bash
cat ~/duckdns/duck.log
```

You should see a response `OK` indicating whether the update was successful.
