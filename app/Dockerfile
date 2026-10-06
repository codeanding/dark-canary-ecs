# APP_VERSION picks the release to build (a folder under src/); nothing switches at runtime.
FROM node:24-alpine AS build
ARG APP_VERSION
RUN test -n "$APP_VERSION" || (echo "build with --build-arg APP_VERSION=v1|v2-broken|v2-fixed" && false)
RUN corepack enable
WORKDIR /app
COPY package.json pnpm-lock.yaml tsconfig.json ./
RUN pnpm install --frozen-lockfile
COPY src/common ./src/common
COPY src/${APP_VERSION} ./src/release
RUN pnpm run build

FROM node:24-alpine
ARG APP_VERSION
WORKDIR /app
ENV APP_VERSION=${APP_VERSION} NODE_ENV=production
COPY --from=build /app/dist ./dist
COPY public ./public
USER node
EXPOSE 3000
CMD ["node", "dist/release/index.js"]
