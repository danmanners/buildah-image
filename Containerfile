# stable/Containerfile
# Code heavily taken from here: https://github.com/containers/buildah/blob/db8d5921a770e7536b34c56d062b47795b548d35/contrib/buildahimage/stable/Containerfile
FROM registry.fedoraproject.org/fedora:36
LABEL org.opencontainers.image.source="https://github.com/danmanners/buildah-image"

RUN useradd build && \
    dnf -y update && \
    rpm --setcaps shadow-utils 2>/dev/null && \
    dnf -y install \
    podman \
    buildah \
    skopeo \
    fuse-overlayfs \
    ceph-fuse \
    cpp \
    --exclude container-selinux && \
    dnf -y clean all && \
    rm -rf /var/cache /var/log/dnf* /var/log/yum.*

ADD https://raw.githubusercontent.com/containers/buildah/main/contrib/buildahimage/stable/containers.conf /etc/containers/

# Copy & modify the defaults to provide reference if runtime changes needed.
# Changes here are required for running with fuse-overlay storage inside container.
RUN sed -e 's|^#mount_program|mount_program|g' \
    -e '/additionalimage.*/a "/var/lib/shared",' \
    -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' \
    /usr/share/containers/storage.conf \
    > /etc/containers/storage.conf; \
    chmod 644 /etc/containers/storage.conf

RUN mkdir -p /var/lib/shared/overlay-images \
    /var/lib/shared/overlay-layers \
    /var/lib/shared/vfs-images \
    /var/lib/shared/vfs-layers && \
    touch /var/lib/shared/overlay-images/images.lock && \
    touch /var/lib/shared/overlay-layers/layers.lock && \
    touch /var/lib/shared/vfs-images/images.lock && \
    touch /var/lib/shared/vfs-layers/layers.lock

# Define uid/gid ranges for our user https://github.com/containers/buildah/issues/3053
RUN echo -e "build:1:999\nbuild:1001:64535" > /etc/subuid; \
    echo -e "build:1:999\nbuild:1001:64535" > /etc/subgid; \
    mkdir -p /home/build/.local/share/containers; \
    chown -R build:build /home/build

VOLUME /var/lib/containers
VOLUME /home/build/.local/share/containers

# Set an environment variable to default to chroot isolation for RUN
# instructions and "buildah run".
ENV BUILDAH_ISOLATION=chroot
