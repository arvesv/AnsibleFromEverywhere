FROM python:3.12-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive \
    ANSIBLE_FORCE_COLOR=True

# Install required system tools for Ansible SSH connectivity and automation
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-client \
    sshpass \
    git \
    rsync \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Install Python requirements
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Install Ansible collections
COPY requirements.yml .
RUN ansible-galaxy collection install -r requirements.yml -p collections

# Copy repository code
COPY . .

# Ensure standard user exists and owns workspace
RUN useradd -m -s /bin/bash -u 1000 ansible && \
    chown -R ansible:ansible /workspace

USER ansible

ENTRYPOINT ["ansible-playbook"]
CMD ["playbooks/hello-world.yml"]

