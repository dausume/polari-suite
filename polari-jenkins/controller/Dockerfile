# The controller doubles as the single build node (host-tier, one box):
# jenkins lts + the toolchain the suite's builders need. Plugins pinned
# by the list; Configuration as Code makes the instance reproducible.
FROM jenkins/jenkins:lts-jdk21
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg git rsync jq python3 python3-pip python3-venv \
        dpkg-dev apt-utils fakeroot binutils openssh-client openjdk-21-jdk-headless \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
    && echo "deb [signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y --no-install-recommends docker-ce-cli docker-buildx-plugin docker-compose-plugin \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*
# gh (GitHub Releases route) + cosign (image signing) — pinned downloads
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh && rm -rf /var/lib/apt/lists/* \
    && curl -fsSLo /usr/local/bin/cosign https://github.com/sigstore/cosign/releases/download/v2.4.1/cosign-linux-amd64 \
    && chmod 0755 /usr/local/bin/cosign
# Jenkins' OWN runtime stays the image's Temurin JRE-style JDK at
# /opt/java/openjdk (first on PATH, so `java` is unchanged). But that layout
# ships no jmods, and jpackage/jlink cannot link a runtime without them —
# polari-app-shell/shells/build-shared-shell.sh died with
# "jlink failed with: Module java.rmi not found". Debian's openjdk-21-jdk-headless
# (installed above) carries jmods/ AND jpackage, so the BUILD steps that need a
# linkable JDK point JAVA_HOME here, stage-scoped, and nothing else moves.
# No JavaFX jmods are needed: build-shared-shell.sh packages in classpath mode
# (--input lib), so jlink only ever resolves java.*/jdk.* system modules.
ENV POLARI_BUILD_JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
USER jenkins
COPY entrypoint.sh /usr/local/bin/polari-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/polari-entrypoint.sh"]
