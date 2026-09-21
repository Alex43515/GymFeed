FROM node:24-alpine AS deps
WORKDIR /app/marketing
COPY marketing/package.json marketing/package-lock.json ./
RUN npm ci --omit=dev

FROM node:24-alpine
ENV NODE_ENV=production
WORKDIR /app
RUN apk add --no-cache ffmpeg fontconfig
COPY --from=deps /app/marketing/node_modules ./marketing/node_modules
COPY marketing ./marketing
COPY docs/GYMFEED_MARKETING_PRODUCT_BRIEF.md ./docs/GYMFEED_MARKETING_PRODUCT_BRIEF.md
COPY docs/marketing/screenshots ./docs/marketing/screenshots
COPY docs/marketing/reference-screens ./docs/marketing/reference-screens
COPY docs/marketing/app-captures ./docs/marketing/app-captures
COPY assets/fonts/Poppins-Regular.ttf assets/fonts/Poppins-SemiBold.ttf assets/fonts/Poppins-Bold.ttf ./assets/fonts/
COPY assets/fonts/Poppins-Regular.ttf assets/fonts/Poppins-SemiBold.ttf assets/fonts/Poppins-Bold.ttf /usr/share/fonts/truetype/poppins/
RUN fc-cache -f
USER node
WORKDIR /app/marketing
EXPOSE 3000
CMD ["node", "src/server.mjs"]

