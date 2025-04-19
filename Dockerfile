# Start from the code-server Debian base image
FROM codercom/code-server:3.10.2

# Switch to root to install system packages
USER root

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3 \
    python3-pip

# Optional: alias `python` to `python3`
RUN ln -s /usr/bin/python3 /usr/bin/python

# --- Install Node.js using NVM ---
ENV NVM_DIR=/home/coder/.nvm
ENV NODE_VERSION=18.18.2

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    nvm use default && \
    ln -s "$NVM_DIR/versions/node/v$NODE_VERSION/bin/node" /usr/bin/node && \
    ln -s "$NVM_DIR/versions/node/v$NODE_VERSION/bin/npm" /usr/bin/npm

# --- Install rclone ---
RUN curl https://rclone.org/install.sh | bash

# Fix permissions
RUN chown -R coder:coder /home/coder/.local

# Switch back to the coder user
USER coder

# Apply VS Code settings
COPY deploy-container/settings.json .local/share/code-server/User/settings.json

# Use bash shell
ENV SHELL=/bin/bash
# Install unzip + rclone (support for remote filesystem)
# Copy rclone tasks
RUN sudo apt-get update && sudo apt-get install unzip -y
RUN curl https://rclone.org/install.sh | sudo bash

# Copy rclone tasks
COPY deploy-container/rclone-tasks.json /tmp/rclone-tasks.json
# Fix permissions for code-server
# Set port
RUN sudo chown -R coder:coder /home/coder/.local
# Set port
ENV PORT=8080

# Use our custom entrypoint script
COPY deploy-container/entrypoint.sh /usr/bin/deploy-container-entrypoint.sh
ENTRYPOINT ["/usr/bin/deploy-container-entrypoint.sh"]
