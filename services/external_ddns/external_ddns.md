# Public dynamic DNS Service

In order to access services hosted in a home lab from the internet, it is often
necessary to have a domain name that points to the public IP address of the home
network. This service provides a way to automatically update a DNS record with the
current public IP address of the home network, allowing users to access their
services using a consistent domain name.

## DuckDNS

- [Official Site](https://www.duckdns.org/)

### Deployment

#### Bare-metal deployment

Installation via linux cron. For this you need first `cron` and `curl`
installed. Test it with:

```bash
ps -ef | grep cr[o]n
```

```bash
curl --version
```

Now let's install it:

```bash
mkdir duckdns
cd duckdns
vi duck.sh
```

Copy and paste the following code into `duck.sh`, replacing `your-domain`
and `your-token` with your actual DuckDNS domain and token:

```bash
export duckdns_token="your-token"
export duckdns_domain="your-domain"
echo url="https://www.duckdns.org/update?domains=${duckdns_domain}&token=${duckdns_token}&ip=" | curl -k -o ~/duckdns/duck.log -K -
```

Make the script executable:

```bash
chmod +x duck.sh
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
