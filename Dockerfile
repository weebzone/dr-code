# Start from the code-server Debian base image
FROM codercom/code-server:3.10.2

# 1) Switch to root to install system packages
USER root

# 2) Install system dependencies (remove python3-pip; we'll install pip ourselves)
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3

# 3) Alias python -> python3
RUN ln -sf /usr/bin/python3 /usr/bin/python

# 4) Install pip for Python 3.7 (uses the 3.7‑specific installer)
RUN curl -sS https://bootstrap.pypa.io/pip/3.7/get-pip.py | python3

# 5) Ensure pip3 is on PATH and symlink pip -> pip3
RUN ln -sf /usr/local/bin/pip3 /usr/local/bin/pip

# 6) Create NVM_DIR and chown
RUN mkdir -p /home/coder/.nvm && chown -R coder:coder /home/coder/.nvm

# 7) Install Node.js via NVM as the coder user
USER coder
ENV NVM_DIR=/home/coder/.nvm
ENV NODE_VERSION=18.18.2
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    echo "export NVM_DIR=\"$NVM_DIR\"" >> ~/.bashrc && \
    echo "[ -s \"$NVM_DIR/nvm.sh\" ] && \. \"$NVM_DIR/nvm.sh\"" >> ~/.bashrc

# 8) Bring back your existing steps…

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

# Custom entrypoint
COPY deploy-container/entrypoint.sh /usr/bin/deploy-container-entrypoint.sh
ENTRYPOINT ["/usr/bin/deploy-container-entrypoint.sh"]
