# Step 1: Use an official OpenJDK runtime as a parent image
FROM eclipse-temurin:17-jre-jammy

# Step 2: Set the working directory inside the container
WORKDIR /app

# Step 3: Copy the JAR file from the target directory into the container
# Using a wildcard (*) ensures it works even if the version or name changes
COPY target/*.jar app.jar

# Step 4: Expose the port your application runs on (change 8080 if needed)
EXPOSE 8080

# Step 5: Command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
