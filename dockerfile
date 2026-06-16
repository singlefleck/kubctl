# Build stage
FROM elixir:1.20.1-otp-27-slim AS build

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && mix local.rebar --force

# Set build environment
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy compile-time config files before compiling
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib

# Compile the application
RUN mix compile

# Build the release
COPY config/runtime.exs config/
RUN mix release

# ---------------------------------------------------------
# Final stage: minimal runtime image
FROM debian:bookworm-slim AS app

# Install runtime dependencies
RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl ca-certificates && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

# Copy the release from the build stage
# COPY --from=build /app/_build/prod/rel/rest_api ./
COPY --from=build /app/_build/prod/rel/kubctl ./


# Set environment variables
ENV PHX_SERVER=true
ENV MIX_ENV=prod

# Expose the port
EXPOSE 4000

# Start the application
# CMD ["bin/rest_api", "start"]

# FIX IS HERE: Change "rest_api" to "kubctl"
CMD ["bin/kubctl", "start"] 