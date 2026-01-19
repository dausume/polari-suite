FROM nginx:latest

# Create certificate directories
RUN mkdir -p /etc/nginx/certs/ca

# CA certificate for verifying upstream services
COPY certs/ca/pol-ca.crt /etc/nginx/certs/ca/pol-ca.crt

# Proxy certificate and key for TLS termination
COPY certs/pol-proxy.crt /etc/nginx/certs/pol-proxy.crt
COPY certs/pol-proxy.key /etc/nginx/certs/pol-proxy.key

# Nginx configuration - use ARG to select dev or prod
ARG NGINX_CONF=nginx.prod.conf
COPY ${NGINX_CONF} /etc/nginx/nginx.conf

# Expose ports - all Cloudflare HTTPS compatible
# Prod: 80, 443
# Dev: 2053, 2083, 2087, 2096, 8443
EXPOSE 80
EXPOSE 443
EXPOSE 2053
EXPOSE 2083
EXPOSE 2087
EXPOSE 2096
EXPOSE 8443

CMD ["nginx", "-g", "daemon off;"]
