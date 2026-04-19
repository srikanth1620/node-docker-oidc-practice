# Minimal Dockerfile for practice (Node.js Docker demo)

FROM node:18-alpine

WORKDIR /app

# Create a simple test file so the build succeeds
RUN echo 'console.log("Hello from Node.js Docker demo using OIDC!");' > app.js

EXPOSE 8080

CMD ["node", "app.js"]