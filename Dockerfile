FROM codercom/code-server:latest

LABEL maintainer="https://github.com/sinojelly"
LABEL decription="VSCode code-server with java, c/c++, fluter, dart, android sdk installed"

USER root
ENV USER_HOME=/home/coder
ENV ANDROID_HOME=$USER_HOME/tools/android_sdk

RUN mkdir -p $ANDROID_HOME && mkdir $USER_HOME/code
WORKDIR $USER_HOME/tools

# Install tools, include java, gcc, 
RUN apt-get update &&\
         apt-get install  -y --no-install-recommends  curl wget gnupg less lsof net-tools git apt-utils default-jdk gcc g++ make gdb build-essential cmake manpages-dev unzip xz-utils

# Setup python development
RUN apt-get install python3.7 python3-pip inetutils-ping python3-venv -y
RUN python3.7 -m pip install pip && python3.7 -m pip install wheel && python3.7 -m pip install flake8

# FLUTTER
RUN apt-get install xz-utils -y 
RUN wget https://storage.googleapis.com/flutter_infra/releases/stable/linux/flutter_linux_1.22.6-stable.tar.xz
RUN tar xf ./flutter_linux_1.22.6-stable.tar.xz
# install dart
RUN ./flutter/bin/dart
ENV PATH="${PATH}:$USER_HOME/tools/flutter/bin"
RUN flutter precache

# Android SDK
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-6858069_latest.zip
RUN unzip commandlinetools-linux-6858069_latest.zip
ENV PATH="${PATH}:$USER_HOME/tools/cmdline-tools/bin"
RUN echo y | sdkmanager --sdk_root=$ANDROID_HOME "platform-tools" "platforms;android-29"
RUN echo y | sdkmanager --sdk_root=$ANDROID_HOME --install "ndk;21.3.6528147"

ENV PATH="${PATH}:$ANDROID_HOME/platform-tools"
RUN flutter doctor

#VSCode Plugins
RUN code-server --install-extension rust-lang.rust \
    && code-server --install-extension vscjava.vscode-java-pack \
    && code-server --install-extension fwcd.kotlin \
    && code-server --install-extension ms-vscode.cpptools \
    && code-server --install-extension dart-code.dart-code \
    && code-server --install-extension dart-code.flutter \
    && code-server --install-extension shd101wyy.markdown-preview-enhanced \
    && code-server --install-extension ms-python.python \
    && code-server --install-extension eamodio.gitlens \
    && code-server --install-extension ms-dotnettools.csharp \
    && code-server --install-extension redhat.java \
    && code-server --install-extension vscjava.vscode-java-pack \
    && code-server --install-extension golang.go \
    && code-server --install-extension ms-azuretools.vscode-docker \
    && code-server --install-extension formulahendry.code-runner \
    && code-server --install-extension ms-vscode.powershell \
    && code-server --install-extension ms-toolsai.jupyter \
    && code-server --install-extension davidanson.vscode-markdownlint \
    && code-server --install-extension shan.code-settings-sync \
    && code-server --install-extension alexisvt.flutter-snippets \
    && code-server --install-extension nash.awesome-flutter-snippets \
    && code-server --install-extension yzane.markdown-pdf \
    && code-server --install-extension dbankier.vscode-instant-markdown \
    && code-server --install-extension goessner.mdmath \
    && code-server --install-extension alanwalk.markdown-toc \
    && code-server --install-extension mdickin.markdown-shortcuts \
    && code-server --install-extension pkief.markdown-checkbox \
    && code-server --install-extension jebbs.markdown-extended \
    && code-server --install-extension kasik96.swift 

WORKDIR $USER_HOME/code


# In data volume: home/coder/.ssh  &&  home/coder/.gitconfig && home/coder/project
VOLUME [ "/data" ]

# code-server settings
USER coder:coder
COPY --chown=coder:coder settings.json /home/coder/.local/share/code-server/User/settings.json

# Init script for empty volume config structure
COPY tools/init-config.sh /usr/local/bin/init-config
RUN sudo chmod 755 /usr/local/bin/init-config

# create config directories and links for persistent use
#RUN sudo mkdir -p /config
#RUN sudo chown coder:coder /config
#RUN mkdir -p /config/.ssh
#RUN touch /config/.gitconfig
# these links to the permanent volume 
#RUN ln -s /config/.ssh /data/home/coder/.ssh
#RUN ln -s /config/.gitconfig /data/home/coder/.gitconfig

#WORKDIR /data/home/coder/project

# http port. Do not expose to the public internet directly!
EXPOSE 8080

ENTRYPOINT ["dumb-init", "--"]
# Make sure we initialize the config if run for the very first time
CMD ["bash", "-c", "init-config && code-server", "--host", "0.0.0.0"]
