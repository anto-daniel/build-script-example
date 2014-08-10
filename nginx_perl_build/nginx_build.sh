#!/bin/bash

hostname=$(hostname -f)
nginx_html_dir="/srv/www/$hostname"

apt-get update
apt-get upgrade -y
apt-get install nginx spawn-fcgi fcgiwrap curl -y

mkdir -p $nginx_html_dir/public_html
mkdir -p $nginx_html_dir/logs
chown -R www-data:www-data $nginx_html_dir

build_conf_file() {
cat > /etc/nginx/sites-available/$hostname <<EOM
server {
    listen   80;
    server_name $hostname;
    access_log $nginx_html_dir/logs/access.log;
    error_log $nginx_html_dir/logs/error.log;
    root   $nginx_html_dir/public_html;

    location / {
        index  index.html index.htm;
    }

    location ~ \.pl$ {
        gzip off;
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/run/fcgiwrap.socket;
        fastcgi_index index.pl;
        fastcgi_param SCRIPT_FILENAME $nginx_html_dir/public_html\$fastcgi_script_name;
    }
}

EOM

}

cd /etc/nginx/sites-enabled/
rm -rfv /etc/nginx/sites-enabled/*
ln -s /etc/nginx/sites-available/$hostname

/etc/init.d/fcgiwrap start
/etc/init.d/nginx start

build_perl_file() {

cat > $nginx_html_dir/public_html/test.pl <<EOM
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

}


build_conf_file
build_perl_file

chown www-data:www-data $nginx_html_dir/public_html/test.pl
chmod a+x $nginx_html_dir/public_html/test.pl
curl http://localhost/test.pl
