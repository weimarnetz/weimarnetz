sed "\| \* \* \* .*reset_deaf_phys.*|d" -i /etc/crontabs/root
echo "*/20 * * * * /usr/sbin/reset_deaf_phys.sh" >> /etc/crontabs/root
