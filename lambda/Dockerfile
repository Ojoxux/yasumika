# syntax=docker/dockerfile:1

FROM haskell:9.10-bookworm AS build

WORKDIR /build

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libgmp-dev \
    libssl-dev \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

COPY yasumi.cabal ./
COPY app ./app
COPY exe ./exe
COPY test ./test
COPY data ./data

RUN mkdir -p /out \
  && cabal update \
  && cabal build yasumi --enable-optimization=2 \
  && cp "$(find dist-newstyle/build -type f -path '*/x/yasumi/*/build/yasumi/yasumi' -print -quit)" /out/yasumi \
  && chmod +x /out/yasumi

FROM public.ecr.aws/lambda/provided:al2023-x86_64

COPY --from=build /out/yasumi ${LAMBDA_TASK_ROOT}/yasumi
COPY data/calendar.json ${LAMBDA_TASK_ROOT}/data/calendar.json
COPY lambda/bootstrap ${LAMBDA_RUNTIME_DIR}/bootstrap

RUN chmod 755 "${LAMBDA_RUNTIME_DIR}/bootstrap" "${LAMBDA_TASK_ROOT}/yasumi"

ENV CALENDAR_PATH=${LAMBDA_TASK_ROOT}/data/calendar.json

# Use custom bootstrap instead of the base image entrypoint (which expects a handler name).
ENTRYPOINT ["/var/runtime/bootstrap"]
