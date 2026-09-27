# APP_VERSION picks which release to build (a folder under src/), like checking out a tag.
# The resulting image contains only that release's code — nothing switches at runtime.
FROM node:22-alpine AS build
ARG APP_VERSION
WORKDIR /app
COPY package*.json tsconfig.json ./
RUN npm install
COPY src/common ./src/common
COPY src/${APP_VERSION} ./src/release
RUN npm run build

FROM node:22-alpine
ARG APP_VERSION
WORKDIR /app
ENV APP_VERSION=${APP_VERSION} NODE_ENV=production
COPY --from=build /app/dist ./dist
USER node
EXPOSE 3000
CMD ["node", "dist/release/index.js"]
