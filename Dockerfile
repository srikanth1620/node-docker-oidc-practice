FROM node:18-alpine

WORKDIR /app

# The backslash after RUN allows the shell to see the heredoc as part of the command
RUN cat <<'EOF' > app.js
const http = require('http');

const port = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello from Node.js Docker App!\n\nDeployed successfully using OIDC + ACR + App Service\n');
});

server.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
EOF

EXPOSE 8080

CMD ["node", "app.js"]

