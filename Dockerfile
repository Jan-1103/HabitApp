


# syntax=docker/dockerfile:1

# Stage 1: Build the application
FROM maven:3.9-eclipse-temurin-21 AS build

WORKDIR /app

COPY pom.xml .

# Download dependencies and cache them
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B dependency:go-offline -Dmaven.wagon.http.retryHandler.count=5

COPY src ./src

# Build the application using cached dependencies
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B clean package -DskipTests -Dmaven.wagon.http.retryHandler.count=5

# Stage 2: Run the application
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Create a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy the generated JAR
COPY --from=build /app/target/*.jar app.jar

# Set non-root permissions
RUN chown appuser:appgroup app.jar

USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
