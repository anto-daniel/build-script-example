#!/bin/bash

apt-get update
apt-get upgrade -y
apt-get install nginx spawn-fcgi fcgiwrap curl -y

mkdir -p /srv/www/nginx.example.com/public_html
mkdir -p /srv/www/nginx.example.com/logs
chown -R www-data:www-data /srv/www/nginx.example.com

cat > /etc/nginx/sites-available/nginx.example.com <<EOM
server {
    listen   80;
    server_name nginx.example.com example.com;
    access_log /srv/www/nginx.example.com/logs/access.log;
    error_log /srv/www/nginx.example.com/logs/error.log;
    root   /srv/www/nginx.example.com/public_html;

    location / {
        index  index.html index.htm;
    }

    location ~ \.pl$ {
        gzip off;
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/run/fcgiwrap.socket;
        fastcgi_index index.pl;
        fastcgi_param SCRIPT_FILENAME /srv/www/nginx.example.com/public_html\$fastcgi_script_name;
    }
}

EOM

cd /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/nginx.example.com

/etc/init.d/fcgiwrap start
/etc/init.d/nginx start

cat > /srv/www/nginx.example.com/public_html/test.pl <<EOM
#!/usr/bin/perl

print "Content-type:text/html\n\n";
print <<EndOfHTML;
<html><head><title>Perl Environment Variables</title></head>
<body>
<h1>Perl Environment Variables</h1>
EndOfHTML

foreach \$key (sort(keys %ENV)) {
    print "\$key = \$ENV{\$key}<br>\n";
}

print "</body></html>";

EOM

chmod a+x /srv/www/nginx.example.com/public_html/test.pl

curl http://localhost/index.pl
