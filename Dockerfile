FROM ubuntu:22.04 AS builder

RUN export DEBIAN_FRONTEND=noninteractive \
	&& ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

RUN apt-get update && apt-get install -y --no-install-recommends cmake git \
		libluajit-5.1-dev unzip	build-essential curl zip tar \
		libglew-dev libx11-dev libncurses5-dev libopenal-dev \
		libssl-dev libvorbis-dev mercurial zlib1g-dev tzdata \
		&& dpkg-reconfigure --frontend noninteractive tzdata \
		pkg-config ninja-build \
		&& apt-get clean \
		&& rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone https://github.com/microsoft/vcpkg
RUN ./vcpkg/bootstrap-vcpkg.sh

WORKDIR /opt/vcpkg
COPY vcpkg.json /opt/vcpkg/
RUN /opt/vcpkg/vcpkg --feature-flags=binarycaching,manifests,versions install

COPY ./ /otclient/

WORKDIR /otclient/build/
RUN export VCPKG_ROOT=/opt/vcpkg/ && cmake --preset linux-release && cmake --build --preset linux-release

FROM ubuntu:22.04

# RUN apt-get update; \
# 	apt-get install -y \
# 	libglew2.1 \
# 	libopenal1 \
# 	libopengl0 \
# 	&& apt-get clean && apt-get autoclean

COPY --from=builder /otclient /otclient
COPY ./data/ /otclient/data/.
COPY ./mods/ /otclient/mods/.
COPY ./modules/ /otclient/modules/.
COPY ./init.lua /otclient/.
WORKDIR /otclient
CMD ["./otclient"]
