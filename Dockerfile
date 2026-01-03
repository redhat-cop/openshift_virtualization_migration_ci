FROM registry.access.redhat.com/ubi9

ENV PYTHON_VERSION=3.12 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    APP_ROOT=/opt/app-root \
    HOME=/opt/app-root/src

# /opt/app-root/bin - the main venv
# /opt/app-root/src/bin - app-specific binaries
# /opt/app-root/src/.local/bin - tools like pipenv
ENV PATH=$APP_ROOT/bin:$HOME/bin:$HOME/.local/bin:$PATH

# Ensure the virtual environment is active in interactive shells
ENV BASH_ENV=${APP_ROOT}/bin/activate \
    ENV=${APP_ROOT}/bin/activate \
    PROMPT_COMMAND=". ${APP_ROOT}/bin/activate"

# glibc-langpack-en is needed to set locale to en_US and disable warning about it
RUN INSTALL_PKGS="git gcc python3 python3-devel python3.11 python3.11-devel python3.12 python3.12-devel glibc-langpack-en" && \
    dnf -y --setopt=tsflags=nodocs --setopt=install_weak_deps=0 install $INSTALL_PKGS && \
    dnf -y clean all --enablerepo='*'

WORKDIR ${HOME}

# - Create a Python virtual environment for use by any application to avoid
#   potential conflicts with Python packages preinstalled in the main Python
#   installation.
RUN \
    python3.12 -m venv ${APP_ROOT} && \
    python3.12 -m pip install --upgrade pip

COPY requirements-ci.txt .
COPY test-requirements.txt .

RUN pip install --no-cache-dir -r requirements-ci.txt
RUN pip install --no-cache-dir -r test-requirements.txt

# GitHub actions should run as root user