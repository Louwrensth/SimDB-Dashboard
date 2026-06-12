FROM oven/bun:1 AS build

WORKDIR /app

COPY dashboard/package.json dashboard/bun.lock ./dashboard/

WORKDIR /app/dashboard
RUN bun install --frozen-lockfile

COPY dashboard/ ./
RUN bun run build

FROM nginx:1.27-alpine

COPY docker/dashboard.nginx /etc/nginx/conf.d/default.conf
COPY --from=build /app/dashboard/dist /usr/share/nginx/html/dashboard

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]