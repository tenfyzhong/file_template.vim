worker_processes 48;

error_log /var/log/nginx/error.log warn;
pid       /var/run/nginx.pid;
daemon    off;

events {
    use epoll;
    worker_connections 8192;
}

http {
    include      /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    open_log_file_cache max=1000 inactive=20s min_uses=2 valid=1m;

    access_log /var/log/nginx/access.log;
    sendfile   on;
    charset UTF-8;
    keepalive_timeout 65;
    proxy_cache_path /var/cache/nginx/cache levels=1:2 keys_zone=imgcache:100m inactive=2h max_size=1g;

    ssl_session_cache shared:SSL:100m;
    ssl_session_timeout 20m;


    gzip            on;
    gzip_min_length 2048;
    gzip_types      text/plain application/x-javascript text/css application/xml application/json application/javascript text/javascript;
    gzip_disable    "MSIE [1-6]\.(?!.*SV1)";
    gzip_static     on;
    gzip_proxied    expired no-cache no-store private auth;

    proxy_buffers 128 128k;
    include /etc/nginx/conf.d/*;
}
