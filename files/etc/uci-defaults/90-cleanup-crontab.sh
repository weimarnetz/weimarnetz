!#/bin/sh

sed -i -e '/owm\.lua$/d' /etc/crontabs/root
sed -i -e '/disable_ibss$/d' /etc/crontabs/root
