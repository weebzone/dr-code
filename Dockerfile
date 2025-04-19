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
    python3-pip \
    sudo

# Optional: alias `python` to `python3`
RUN ln -s /usr/bin/python3 /usr/bin/python

# Create the NVM_DIR for coder user
RUN mkdir -p /home/coder/.nvm && chown -R coder:coder /home/coder/.nvm

# Switch to coder user for NVM/Node installation
USER coder
ENV NVM_DIR=/home/coder/.nvm
ENV NODE_VERSION=18.18.2
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# Install NVM and Node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    nvm use default && \
    echo "export NVM_DIR=\"$NVM_DIR\"" >> ~/.bashrc && \
    echo "[ -s \"$NVM_DIR/nvm.sh\" ] && \. \"$NVM_DIR/nvm.sh\"" >> ~/.bashrc

# Apply VS Code settings
COPY deploy-container/settings.json .local/share/code-server/User/settings.json

# Use bash shell
ENV SHELL=/bin/bash

# Install rclone
USER root
RUN curl https://rclone.org/install.sh | bash
COPY deploy-container/rclone-tasks.json /tmp/rclone-tasks.json
RUN chown -R coder:coder /home/coder/.local

# Switch back to coder
USER coder

# Set port
ENV PORT=8080

# Use our custom entrypoint script
COPY deploy-container/entrypoint.sh /usr/bin/deploy-container-entrypoint.sh
ENTRYPOINT ["/usr/bin/deploy-container-entrypoint.sh"]
