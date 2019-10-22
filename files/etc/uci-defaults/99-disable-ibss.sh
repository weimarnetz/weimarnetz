sed "\| \* .*disable_ibss.*|d" -i /etc/crontabs/root
echo "0 18 14 4 * /usr/sbin/disable_ibss" >> /etc/crontabs/root
