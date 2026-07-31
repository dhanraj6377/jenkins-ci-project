# Use the official openjdk image instead of the deprecated 'java' image
FROM openjdk:8-jre-alpine

ADD ./target/account-service.jar /app/
CMD ["java", "-Xmx200m", "-jar", "/app/account-service.jar"]

EXPOSE 6000