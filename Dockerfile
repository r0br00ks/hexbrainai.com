# Builds and runs HexBrain. The database lives in /app/data: mount a volume there to keep it.
FROM node:24-slim AS build
WORKDIR /app
RUN corepack enable
# The public address is baked into the pages (canonical links, sitemap, share previews), so it is a build argument.
ARG HEXBRAIN_PUBLIC_URL
ENV HEXBRAIN_PUBLIC_URL=$HEXBRAIN_PUBLIC_URL
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM node:24-slim
WORKDIR /app
ENV NODE_ENV=production
# git and unzip are used by the data imports (PayloadsAllTheThings, nuclei-templates, Chaos subdomains).
RUN apt-get update && apt-get install -y --no-install-recommends git unzip curl ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && curl -fsSL -o /tmp/bws.zip "https://github.com/bitwarden/sdk-sm/releases/download/bws-v1.0.0/bws-x86_64-unknown-linux-gnu-1.0.0.zip" \
 && unzip -q /tmp/bws.zip -d /usr/local/bin && chmod +x /usr/local/bin/bws && rm -f /tmp/bws.zip
COPY --from=build /app ./
RUN chmod +x /app/docker-entrypoint.sh /app/scripts/refresh.sh
VOLUME /app/data
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:3000/about').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["node", "node_modules/next/dist/bin/next", "start", "-p", "3000"]
