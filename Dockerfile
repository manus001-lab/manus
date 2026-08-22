FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:99 \
    SCREEN_WIDTH=1440 \
    SCREEN_HEIGHT=900 \
    SCREEN_DEPTH=24 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 xfce4-terminal dbus-x11 x11-xserver-utils xvfb x11vnc \
    novnc websockify supervisor sudo python3 python3-pip python3-tk \
    python3-dev scrot imagemagick curl wget ca-certificates gnupg \
    software-properties-common git jq openssl xdotool python3-flask \
    firefox \
    && rm -rf /var/lib/apt/lists/*

RUN install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list \
    && apt-get update && apt-get install -y --no-install-recommends microsoft-edge-stable \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash ubuntuuser \
    && echo 'ubuntuuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntuuser \
    && chmod 0440 /etc/sudoers.d/ubuntuuser \
    && mkdir -p /workspace/screenshots /workspace/backup \
    && chown -R ubuntuuser:ubuntuuser /workspace

COPY docker/supervisord.conf /etc/supervisor/conf.d/gui.conf
COPY docker/startup.sh /usr/local/bin/startup.sh
COPY docker/app /opt/gui-app
COPY policy/allowed-operations.yml /opt/gui-app/allowed-operations.yml
RUN chmod +x /usr/local/bin/startup.sh \
    && python3 -m pip install --break-system-packages --no-cache-dir pyautogui pillow requests pyyaml

WORKDIR /workspace
USER ubuntuuser
EXPOSE 6080 8080
ENTRYPOINT ["/usr/local/bin/startup.sh"]
