# Stage 1: Build with JDK
FROM eclipse-temurin:17-jdk AS build
WORKDIR /workspace
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B
COPY src src
RUN ./mvnw package -DskipTests -B

# Stage 2: Runtime with JRE only
FROM eclipse-temurin:17-jre
LABEL org.opencontainers.image.source="https://github.com/jek-bao-choo/datadog-agentic-plugins"
RUN groupadd --system appgroup && useradd --system --gid appgroup appuser
WORKDIR /app
RUN mkdir -p /app/logs && chown -R appuser:appgroup /app
COPY --from=build --chown=appuser:appgroup \
  /workspace/target/springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback-0.0.1-SNAPSHOT.jar app.jar
USER appuser
EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75.0", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]
