FROM ubuntu:22.04@sha256:1b8d8ff4777f36f19bfe73ee4df61e3a0b789f9aa227d3114ebd3fcfdc42b64

# Environment variables
#######################

ENV MIRROR_DIR='/srv/mirror'
ENV SRC_DIR='/srv/src'
ENV ZIP_DIR='/srv/zips'
ENV LOGS_DIR='/srv/logs'
ENV KEYS_DIR='/srv/keys'
ENV CCACHE_DIR='/srv/ccache'
ENV USERSCRIPTS_DIR='/srv/userscripts'
ENV LMANIFEST_DIR='/srv/local_manifests'
ENV CERTIFICATE_SUBJECT='/CN=android/'
ENV DEVICE_LIST=''
ENV SIGN_BUILDS=false
ENV CRONTAB_TIME='now'
ENV ZIP_SUBDIR=true
ENV LOGS_SUBDIR=true
ENV DELETE_OLD_ZIPS=0
ENV DELETE_OLD_LOGS=0
ENV CLEAN_OUTDIR=false
ENV CLEAN_AFTER_BUILD=true
ENV WITH_GMS=false
ENV OTA_URL=''
ENV BUILD_TYPE='userdebug'
ENV RELEASE_TYPE='UNOFFICIAL'
ENV SIGNATURE_SPOOFING='no'
ENV SIGNATURE_SPOOFING_FORCE=false
ENV CUSTOM_PACKAGES=''
ENV DEBUG=false
ENV USE_CCACHE=1
ENV CCACHE_SIZE='50G'
ENV PARALLEL_JOBS=0
ENV RETRY_FETCHES=0
ENV LOCAL_MIRROR=false
ENV INIT_MIRROR=true
ENV SYNC_MIRROR=true
ENV SYNC_MIRROR_MAIN=false
ENV INCLUDE_PROPRIETARY=false
ENV APPLY_PI_PATCH=true
ENV RESET_VENDOR_UNDO_PATCHES=true
ENV CALL_REPO_INIT=true
ENV CALL_REPO_SYNC=true
ENV CALL_GIT_LFS_PULL=true
ENV PREPARE_BUILD_ENVIRONMENT=true
ENV CALL_BREAKFAST=true
ENV CALL_MKA=true
ENV USER_NAME='Docker CI'
ENV USER_MAIL='noreply@example.com'
ENV BRANCH_NAME='lineage-23.0'

# Manifest URL for the ROM (AxionAOSP by default)
ENV MANIFEST_URL='https://github.com/AxionAOSP/android.git'

# Vendor dir name used for overlays/config (axion by default; will fall back to lineage if missing)
ENV ROM_VENDOR='axion'

ENV USER=root

# Prefer Java 17 for modern Android builds
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# This fixes some issues with terminal colors
ENV TERM=xterm-256color

# Setup the sources list
#########################
RUN apt-get update && apt-get install -y \
  apt-utils \
  software-properties-common \
  && rm -rf /var/lib/apt/lists/*

# Install dependencies
#######################
RUN apt-get update && apt-get install -y \
  bc \
  bison \
  build-essential \
  ccache \
  curl \
  flex \
  g++-multilib \
  gcc-multilib \
  git \
  git-lfs \
  gnupg \
  gperf \
  imagemagick \
  lib32ncurses5-dev \
  lib32readline-dev \
  lib32z1-dev \
  libgl1-mesa-dev \
  liblz4-tool \
  libncurses5 \
  libncurses5-dev \
  libsdl1.2-dev \
  libssl-dev \
  libxml2 \
  libxml2-utils \
  lzop \
  maven \
  openjdk-17-jdk \
  pngcrush \
  python3 \
  rsync \
  schedtool \
  squashfs-tools \
  unzip \
  wget \
  x11proto-core-dev \
  xsltproc \
  zip \
  zlib1g-dev \
  sudo \
  python-is-python3 \
  nano \
  vim \
  zstd \
  file \
  && rm -rf /var/lib/apt/lists/*

# Make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# Install repo tool
#####################
RUN curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo && chmod a+x /usr/local/bin/repo

# Add a user named "android" and make it a sudoer
##############################################
RUN useradd -m -G sudo -s /bin/bash android && \
    echo "android ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up build environment
###########################
RUN mkdir -p \
    $MIRROR_DIR \
    $SRC_DIR \
    $ZIP_DIR \
    $LOGS_DIR \
    $KEYS_DIR \
    $CCACHE_DIR \
    $USERSCRIPTS_DIR \
    $LMANIFEST_DIR

# Add the init scripts
#######################
COPY src/init.sh /root/init.sh
COPY src/new_build.sh /root/new_build.sh
COPY src/legacy-build.sh /root/legacy-build.sh
COPY src/build_manifest.py /root/build_manifest.py
COPY src/clean_up.py /root/clean_up.py
COPY src/make_key /root/make_key
COPY src/packages_updater_strings.xml /root/packages_updater_strings.xml

# apt preferences
COPY apt_preferences /etc/apt/preferences.d/99-apt_preferences

# Set execute permissions
#########################
RUN chmod +x /root/init.sh /root/new_build.sh /root/legacy-build.sh /root/make_key

# Enable git-lfs
#################
RUN git lfs install --system

# Set the work directory
########################
WORKDIR $SRC_DIR

# Allow redirection of stdout to docker logs
############################################
RUN ln -sf /proc/1/fd/1 /var/log/docker.log

# Set the entry point to init.sh
################################
ENTRYPOINT /root/init.sh
