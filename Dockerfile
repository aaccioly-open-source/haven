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
FROM debian:bookworm-slim

WORKDIR /app

# Add environment variables for UID and GID
ARG DOCKER_UID=1000
ARG DOCKER_GID=1000

# Create a new group and user
RUN groupadd -g ${DOCKER_GID} appgroup && \
    useradd -u ${DOCKER_UID} -g appgroup -m appuser

# Copy the built application
COPY --from=builder /app/main .
# Change ownership of the working directory
RUN chown -R appuser:appgroup /app

# Switch to the new user
USER appuser

# Expose the port that the application will run on
ARG RELAY_PORT=3355
EXPOSE ${RELAY_PORT}

# Set the command to run the executable
CMD ["./main"]
