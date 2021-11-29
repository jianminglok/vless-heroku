#!/bin/sh

# Get V2/X2 binary and decompress binary
mkdir /tmp/v2ray
curl --retry 10 --retry-max-time 60 -L -H "Cache-Control: no-cache" -fsSL github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip -o /tmp/v2ray/v2ray.zip
busybox unzip /tmp/v2ray/v2ray.zip -d /tmp/v2ray
install -m 755 /tmp/v2ray/v2ray /usr/local/bin/v2ray
install -m 755 /tmp/v2ray/v2ctl /usr/local/bin/v2ctl
install -m 755 /tmp/v2ray/geosite.dat /usr/local/bin/geosite.dat
install -m 755 /tmp/v2ray/geoip.dat /usr/local/bin/geoip.dat
v2ray -version
rm -rf /tmp/v2ray

# V2/X2 new configuration
install -d /usr/local/etc/v2ray
cat << EOF > /usr/local/etc/v2ray/config.json
{
    "log": {
        "loglevel": "none"
    },
    "inbounds": [
        {   
            "port": ${PORT},
            "protocol": "vless",
            "sniffing": {
                "enabled": true,
                "destOverride": ["http","tls"]
            },
            "settings": {
                "clients": [
                    {
                        "id": "$ID",
                        "level": 0,
                        "email": "love@v2fly.org"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "allowInsecure": false,
                "wsSettings": {
                  "path": "/$ID-vless"
                }
            }
        },
        {   
            "port": ${PORT},
            "protocol": "trojan",
            "sniffing": {
                "enabled": true,
                "destOverride": ["http","tls"]
            },
            "settings": {
                "clients": [
                    {
                        "password":"$ID",
                        "email": "love@v2fly.org"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "allowInsecure": false,
                "wsSettings": {
                  "path": "/$ID-trojan"
                }
            }
        },
        {
            "listen": "0.0.0.0",
            "port": 8080,
            "protocol": "dokodemo-door",
            "settings": {
              "address": "0.0.0.0",
              "port": 80,
              "network": "tcp",
              "followRedirect": false
            },
            "sniffing": {
              "enabled": true,
              "destOverride": ["http"]
            },
            "tag": "unblock-80"
        },
        {
            "listen": "0.0.0.0",
            "port": 8443,
            "protocol": "dokodemo-door",
            "settings": {
              "address": "0.0.0.0",
              "port": 443,
              "network": "tcp",
              "followRedirect": false
            },
            "sniffing": {
              "enabled": true,
              "destOverride": ["tls"]
            },
            "tag": "unblock-443"
        }
    ],
    "routing": {
        "domainStrategy": "IPOnDemand",
        "rules": [
            {
              "type": "field",
              "inboundTag": ["unblock-80", "unblock-443"],
              "outboundTag": "direct"
            }
        ]
    },
    "outbounds": [
        {
          "protocol": "freedom",
          "settings": {
            "domainStrategy": "UseIPv4"
          },
          "tag": "IPv4-out"
        },
        {
          "tag": "direct",
          "protocol": "freedom",
          "settings": {}
        },
        {
          "protocol": "blackhole",
          "tag": "blackhole-out"
        }
    ],
    "dns": {
        "servers": [
            "https://dns.google/dns-query",
            "https://cloudflare-dns.com/dns-query"
        ]
    }
}
EOF

# Run V2/X2
/usr/local/bin/v2ray -config /usr/local/etc/v2ray/config.json
