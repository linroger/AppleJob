#!/bin/bash

# Navigate to the project directory
cd "/Users/rogerlin/XCode Projects/Experimental-alpha"

# Clone the repository
git clone https://github.com/r-huijts/xcode-mcp-server.git .

# Install Node.js dependencies
npm install

# Build the project
npm run build

# Create Claude Desktop config file
mkdir -p ~/Library/Application\ Support/Claude
cat > ~/Library/Application\ Support/Claude/claude_desktop_config.json << EOL
{
  "mcpServers": {
    "xcode-server": {
      "command": "node",
      "args": [
        "/Users/rogerlin/XCode Projects/Experimental-alpha/build/index.js"
      ],
      "env": {
        "PROJECTS_BASE_DIR": "/Users/rogerlin/XCode Projects"
      }
    }
  }
}
EOL

echo "Xcode MCP Server setup complete!"
