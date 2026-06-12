FROM node:24-alpine AS build

WORKDIR /app

COPY dashboard/package.json dashboard/package-lock.json ./dashboard/

WORKDIR /app/dashboard
RUN npm ci

COPY dashboard/ ./
RUN npm run build

FROM nginx:1.27-alpine

COPY docker/dashboard.nginx /etc/nginx/conf.d/default.conf
COPY --from=build /app/dashboard/dist /usr/share/nginx/html/dashboard

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]