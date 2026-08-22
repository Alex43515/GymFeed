FROM node:24-alpine AS deps
WORKDIR /app/marketing
COPY marketing/package.json marketing/package-lock.json ./
RUN npm ci --omit=dev

FROM node:24-alpine
ENV NODE_ENV=production
WORKDIR /app
RUN apk add --no-cache fontconfig
COPY --from=deps /app/marketing/node_modules ./marketing/node_modules
COPY marketing ./marketing
COPY assets/fonts/Poppins-Regular.ttf assets/fonts/Poppins-SemiBold.ttf assets/fonts/Poppins-Bold.ttf ./assets/fonts/
USER node
WORKDIR /app/marketing
EXPOSE 3000
CMD ["node", "src/server.mjs"]

