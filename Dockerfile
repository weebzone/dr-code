# Start from the code-server Debian base image
FROM codercom/code-server:3.10.2

# 1) Switch to root to install system packages
USER root

# 2) Install system packages (including distutils & setuptools for pip)
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3 \
    python3-distutils \
    python3-setuptools

# 3) Alias python -> python3
RUN ln -sf /usr/bin/python3 /usr/bin/python

# 4) Bootstrap pip for Python 3.7
RUN curl -sS https://bootstrap.pypa.io/pip/3.7/get-pip.py | python3 \
 && ln -sf /usr/local/bin/pip3 /usr/local/bin/pip

# 5) Prepare NVM directory
RUN mkdir -p /home/coder/.nvm && chown -R coder:coder /home/coder/.nvm

# 6) Install Node.js via NVM as the coder user
USER coder
ENV NVM_DIR=/home/coder/.nvm
ENV NODE_VERSION=18.18.2
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
 && . "$NVM_DIR/nvm.sh" \
 && nvm install $NODE_VERSION \
 && nvm alias default $NODE_VERSION \
 && echo "export NVM_DIR=\"$NVM_DIR\"" >> ~/.bashrc \
 && echo "[ -s \"$NVM_DIR/nvm.sh\" ] && \. \"$NVM_DIR/nvm.sh\"" >> ~/.bashrc

# 7) Back to root for global installs & directory prep
USER root

# Ensure ~/.local exists for VS Code settings
RUN mkdir -p /home/coder/.local/share/code-server/User

# Install rclone
RUN curl https://rclone.org/install.sh | bash

# Copy your rclone-tasks.json
COPY deploy-container/rclone-tasks.json /tmp/rclone-tasks.json

# Copy VS Code settings into place
COPY deploy-container/settings.json /home/coder/.local/share/code-server/User/settings.json

# 8) Fix ownership on everything under /home/coder
RUN chown -R coder:coder /home/coder

# 9) Switch back to coder, set shell & port, and add entrypoint
USER coder
ENV SHELL=/bin/bash
ENV PORT=8080

COPY deploy-container/entrypoint.sh /usr/bin/deploy-container-entrypoint.sh
ENTRYPOINT ["/usr/bin/deploy-container-entrypoint.sh"]
