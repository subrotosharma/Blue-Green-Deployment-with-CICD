FROM eclipse-temurin:17-jdk-alpine

# Create non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Create app directory and set permissions
ENV APP_HOME /usr/src/app
RUN mkdir -p $APP_HOME && chown -R appuser:appgroup $APP_HOME

# Set working directory
WORKDIR $APP_HOME

# Copy JAR as root and fix permissions
COPY target/*.jar app.jar
RUN chown appuser:appgroup app.jar

# Switch to non-root user
USER appuser

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]
