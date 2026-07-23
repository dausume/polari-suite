# Polari WWW — the informational hub. Static site on nginx: no build stage, no
# runtime, tiny footprint. It links out to the heavier PRF + scorecard apps and
# hosts light Mermaid-based docs, soaking up casual traffic to keep load off them.
FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY site /usr/share/nginx/html
EXPOSE 4200
CMD ["nginx", "-g", "daemon off;"]
