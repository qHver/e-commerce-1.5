# syntax=docker/dockerfile:1.7

ARG BUN_VERSION=1.3.8

FROM oven/bun:${BUN_VERSION}-alpine AS deps
WORKDIR /app

COPY package.json bun.lock turbo.json ./
COPY apps/api/package.json apps/api/package.json
COPY apps/admin-test/package.json apps/admin-test/package.json
COPY apps/storefront/package.json apps/storefront/package.json
COPY apps/vendor/package.json apps/vendor/package.json
COPY packages/admin/package.json packages/admin/package.json
COPY packages/cli/package.json packages/cli/package.json
COPY packages/client/package.json packages/client/package.json
COPY packages/core/package.json packages/core/package.json
COPY packages/create-mercur-app/package.json packages/create-mercur-app/package.json
COPY packages/dashboard-sdk/package.json packages/dashboard-sdk/package.json
COPY packages/dashboard-shared/package.json packages/dashboard-shared/package.json
COPY packages/docs/package.json packages/docs/package.json
COPY packages/registry/package.json packages/registry/package.json
COPY packages/types/package.json packages/types/package.json
COPY packages/vendor/package.json packages/vendor/package.json
COPY packages/providers/payout-stripe-connect/package.json packages/providers/payout-stripe-connect/package.json
COPY integration-tests/package.json integration-tests/package.json
COPY e2e-tests/package.json e2e-tests/package.json
COPY e2e-tests/hosts/admin/package.json e2e-tests/hosts/admin/package.json
COPY e2e-tests/hosts/vendor/package.json e2e-tests/hosts/vendor/package.json

RUN --mount=type=cache,target=/root/.bun/install/cache \
    bun install --frozen-lockfile

FROM deps AS build
WORKDIR /app
COPY . .

RUN bun run --cwd /app/packages/types build \
 && bun run --cwd /app/packages/client build \
 && bun run --cwd /app/packages/dashboard-sdk build \
 && bun run --cwd /app/packages/dashboard-shared build \
 && bun run --cwd /app/packages/cli build \
 && bun run --cwd /app/packages/core build

FROM oven/bun:${BUN_VERSION}-alpine AS runtime
WORKDIR /app

ENV NODE_ENV=production \
    PORT=9000

COPY --from=build --chown=bun:bun /app/package.json ./package.json
COPY --from=build --chown=bun:bun /app/bun.lock ./bun.lock
COPY --from=build --chown=bun:bun /app/turbo.json ./turbo.json
COPY --from=build --chown=bun:bun /app/apps/api ./apps/api
COPY --from=build --chown=bun:bun /app/packages ./packages
COPY --from=build --chown=bun:bun /app/integration-tests/package.json ./integration-tests/package.json
COPY --from=build --chown=bun:bun /app/e2e-tests/package.json ./e2e-tests/package.json

RUN --mount=type=cache,target=/root/.bun/install/cache \
    bun install --frozen-lockfile --production

USER bun
WORKDIR /app/apps/api

EXPOSE 9000

CMD ["bun", "run", "start"]
