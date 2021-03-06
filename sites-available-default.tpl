# Default server configuration
#
server {
        client_max_body_size 20M;
	listen 80 default_server;
	listen [::]:80 default_server;

	# SSL configuration
	#
	# listen 443 ssl default_server;
	# listen [::]:443 ssl default_server;
	#
	# Self signed certs generated by the ssl-cert package
	# Don't use them in a production server!
	#
	# include snippets/snakeoil.conf;

	root /var/www/;

	index index.php index.html index.htm index.nginx-debian.html;

	server_name _;

	location / {
		# First attempt to serve request as file, then
		# as directory, then fall back to displaying a 404.
		#try_files $uri $uri/ =404;
		rewrite "(.*)$" @@WikiPath@@/Hauptseite last;
	}

	# === Wiki: path=wiki ===
	location @@WikiPath@@ {
		try_files $uri @do_wiki_wikipage;
 	}

	location @do_wiki_wikipage {
		rewrite "^@@WikiPath@@$" @@WikiPath@@/ redirect;
		rewrite "^@@WikiPath@@/([^?]*)(?:\?(.*))?$" @@WikiPath@@/index.php?title=$1&$args last;
	}
	
	location @@WikiPath@@/media {
		location ~ ^@@WikiPath@@/media/thumb/(archive/)?[0-9a-f]/[0-9a-f][0-9a-f]/([^/]+)/([0-9]+)px-.*$ {
			try_files $uri @thumb_wiki;
		}
 	}
 
	# pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000

	# Serve .php files using fast-cgi
	location ~ .php$ {
		# Common fastcgi settings
		include		 /etc/nginx/fastcgi_params;
  
		# Php settings
		fastcgi_pass	unix:/var/run/php/php7.0-fpm.sock;
		fastcgi_index   index.php;
		
		# Script filename
		fastcgi_param   SCRIPT_FILENAME $document_root$fastcgi_script_name;
		fastcgi_param HTTP_X_FORWARDED_FOR $http_x_forwarded_for;
	}

	# deny access to .htaccess files, if Apache's document root
	# concurs with nginx's one
	#
	location ~ /\.ht {
		deny all;
	}
	
        location /ontologies {
                 autoindex on;
                 try_files $uri.owl $uri $uri$ld_suffix =404;
        }
}