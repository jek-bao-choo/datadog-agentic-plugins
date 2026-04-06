---
name: setup-html-nginx
description: Static HTML application served by Nginx in Docker
---

# Setup Static HTML App on Nginx

Set up a static HTML application served by Nginx using Docker.

## Instructions

1. Create the static HTML files (e.g., `index.html`, CSS, and any static assets).
2. Create an `nginx.conf` configuration file for serving static content.
3. Create a `Dockerfile` based on the official `nginx` image:
   ```dockerfile
   FROM nginx:alpine
   COPY nginx.conf /etc/nginx/nginx.conf
   COPY html/ /usr/share/nginx/html/
   ```
4. Build and run the Docker container:
   ```bash
   docker build -t html-app .
   docker run -p 8080:80 html-app
   ```
5. Verify the static HTML site is accessible at `http://localhost:8080`.
