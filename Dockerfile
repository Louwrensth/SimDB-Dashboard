FROM node:24-alpine AS build
ARG APP_VERSION=0.0.0-unknown

WORKDIR /app

# App tries git-describe at build time, but there is no .git/
RUN echo "${APP_VERSION}" > .app-version

COPY dashboard/package.json dashboard/package-lock.json ./

RUN npm ci

COPY dashboard/ ./

RUN npm run build

FROM nginx:1.27-alpine

COPY docker/dashboard.nginx /etc/nginx/conf.d/default.conf
# App expects itself at urlpath /dashboard
COPY --from=build /app/dist /usr/share/nginx/html/dashboard

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
