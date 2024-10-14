# Stage 1: Install dependencies
FROM golang:bookworm AS deps

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

# Stage 2: Build the application
FROM golang:bookworm AS builder

WORKDIR /app

COPY --from=deps /go/pkg /go/pkg
COPY . .

RUN go build -ldflags="-w -s" -o main .

# Final stage: Run the application
FROM gcr.io/distroless/base-debian12

WORKDIR /app

# Add environment variables for UID and GID
ARG DOCKER_UID=1000
ARG DOCKER_GID=1000

# Copy the built application
COPY --from=builder --chown=${DOCKER_UID}:${DOCKER_GID} /app/main .

# Switch to the new user
USER ${DOCKER_UID}:${DOCKER_GID}

# Expose the port that the application will run on
ARG RELAY_PORT=3355
EXPOSE ${RELAY_PORT}

# Set the command to run the executable
CMD ["./main"]
