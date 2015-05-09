mirage clean
mirage configure --unix
make
sudo -i 
cd /home/heidi/rwe-dns-server/
make run
exit
ps -e
# find id
kill -9 id 
sudo 
sudo /etc/init.d/main.native start