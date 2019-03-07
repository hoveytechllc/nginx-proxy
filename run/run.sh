#!/bin/bash

HTTPS_REDIRECTION=0
NGINX_CONF_FILE=/etc/nginx/conf.d/default.conf
PROP_SPACING="    "
VALUE_SPACING="\t"

if [ -z $PROXY_PASS ]; then
    echo "Environment variable PROXY_PASS is required."
    exit 1
fi
if [ -z $LISTEN_PROXY ]; then
    
    if [ -z $LISTEN_PORT ]; then
        echo "Environment variable LISTEN_PORT is required."
        exit 1
    fi
    
    if [ -z $LISTEN_DNS_NAME ]; then
        echo "Environment variable LISTEN_DNS_NAME is required."
        exit 1
    fi
fi

if [ ! -z $LISTEN_REDIRECT_PORT ]; then
    HTTPS_REDIRECTION=1
fi

echo "--- > Removing default nginx configuration file."
rm $NGINX_CONF_FILE

if [  $HTTPS_REDIRECTION == 1 ]; then
    echo "--- > Using HTTPS redirection with port $LISTEN_REDIRECT_PORT."
    cat ./redirect-to-https.conf | sed "s|\${LISTEN_REDIRECT_PORT}|$LISTEN_REDIRECT_PORT|g" >> $NGINX_CONF_FILE
fi

if [ -z $LISTEN_PROXY ]; then
    LISTEN_PROXY="listen${VALUE_SPACING}${LISTEN_PORT};\n${PROP_SPACING}server_name${VALUE_SPACING}${LISTEN_DNS_NAME};"

    if [ ! -z $LISTEN_HTTPS_SWARM_SECRET ]; then
        echo "--- > Including SSL Key using swarm secret."
        LISTEN_PROXY=$LISTEN_PROXY"\n${PROP_SPACING}ssl_certificate${VALUE_SPACING}/run/secrets/$LISTEN_HTTPS_SWARM_SECRET.crt;\n${PROP_SPACING}ssl_certificate_key${VALUE_SPACING}/run/secrets/$LISTEN_HTTPS_SWARM_SECRET.key;"
    fi
fi

cat ./reverse-proxy.conf | sed "s|\${LISTEN_PROXY}|$LISTEN_PROXY|g" | sed "s|\${PROXY_PASS}|$PROXY_PASS|g" >> $NGINX_CONF_FILE

echo "--- > Using configuration:"
cat $NGINX_CONF_FILE

echo "--- > Starting Nginx..."
nginx -g "daemon off;"