FROM nvidia/cuda:11.6.0-devel-ubuntu20.04 as builder

ARG FFMPEG_VERSION="5.0"
ARG LIBVAMF_VERSION="2.3.0"
ARG LIBZIMG_VERSION="3.0.3"
ARG LIBFREI0R_VERSION="1.8.0"
ARG NV_HEADER_VERSION="11.1.5.1"
ARG PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/local/lib/pkgconfig"

WORKDIR /ffmpeg-build

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      autoconf \
      automake \
      build-essential \
      ca-certificates \
      cmake \
      frei0r-plugins-dev \
      git \
      glslang-dev \
      ladspa-sdk \
      libaom-dev \
      libass-dev \
      libavc1394-dev \
      libbluray-dev \
      libbs2b-dev \
      libcaca-dev \
      libcdio-dev \
      libcdio-paranoia-dev \
      libcodec2-dev \
      libdc1394-dev \
      libdrm-dev \
      libfdk-aac-dev \
      libfontconfig1-dev \
      libfreetype6-dev \
      libfribidi-dev \
      libgme-dev \
      libgnutls28-dev \
      libgsm1-dev \
      libiec61883-dev \
      libjack-dev \
      liblensfun-dev \
      liblilv-dev \
      liblzma-dev \
      libmfx-dev \
      libmp3lame-dev \
      libmysofa-dev \
      libnuma-dev \
      libopenal-dev \
      libopengl-dev \
      libopenjp2-7-dev \
      libopenmpt-dev \
      libopus-dev \
      libpulse-dev \
      librsvg2-dev \
      librubberband-dev \
      libsdl2-dev \
      libsdl2-dev \
      libshine-dev \
      libsnappy-dev \
      libsoxr-dev \
      libspeex-dev \
      libssh-dev \
      libtheora-dev \
      libtool \
      libtwolame-dev \
      libunistring-dev \
      libva-dev \
      libvdpau-dev \
      libvidstab-dev \
      libvorbis-dev \
      libvpx-dev \
      libwavpack-dev \
      libwebp-dev \
      libvulkan-dev \
      libx264-dev \
      libx265-dev \
      libxcb-shm0-dev \
      libxcb-xfixes0-dev \
      libxcb1-dev \
      libxml2-dev \
      libxvidcore-dev \
      libzmq3-dev \
      libzvbi-dev \
      lv2-dev \
      lzma-dev \
      meson \
      nasm \
      ninja-build \
      ocl-icd-opencl-dev \
      pkg-config \
      texinfo \
      wget \
      yasm \
      zlib1g-dev

RUN git clone -b "n$NV_HEADER_VERSION" https://github.com/FFmpeg/nv-codec-headers.git
RUN cd nv-codec-headers && \
    make install PREFIX=/usr/local && \
    cd ..

RUN git clone -b "v$LIBVAMF_VERSION" https://github.com/Netflix/vmaf.git
RUN mkdir -p vmaf/build && \
    cd vmaf/libvmaf && \
    meson setup \
      -Denable_tests=false \
      -Denable_docs=false \
      --buildtype=release \
      --default-library=static \
      --prefix /usr/local \
      ../build && \
    cd ../build && \
    ninja && \
    ninja install && \
    cd ../..

RUN git clone -b "release-$LIBZIMG_VERSION" https://github.com/sekrit-twc/zimg.git
RUN cd zimg && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local --disable-shared --enable-static && \
    make -j$(nproc) && \
    make -j$(nproc) install && \
    cd ..

RUN git clone -b "n$FFMPEG_VERSION" https://github.com/FFmpeg/FFmpeg.git
RUN cd FFmpeg && \
    mkdir /ffmpeg-bin && \
    PKG_CONFIG_PATH="$PKG_CONFIG_PATH" ./configure \
      --prefix="/usr/local" \
      --bindir="/ffmpeg-bin" \
      --pkg-config-flags="--static" \
      --extra-cflags="-I/usr/local/cuda/include" \
      --extra-ldflags="-L/usr/local/cuda/lib64 -L/lib/x86_64-linux-gnu" \
      --extra-libs="-lpthread -lm" \
      --ld="g++" \
      --enable-gpl \
      --enable-version3 \
      --enable-nonfree \
      --disable-stripping \
      --enable-gnutls \
      --enable-ladspa \
      --enable-libaom \
      --enable-libass \
      --enable-libbluray \
      --enable-libbs2b \
      --enable-libcaca \
      --enable-libcdio \
      --enable-libcodec2 \
      --enable-libfontconfig \
      --enable-libfreetype \
      --enable-libfribidi \
      --enable-libgme \
      --enable-libgsm \
      --enable-libjack \
      --enable-libmp3lame \
      --enable-libmysofa \
      --enable-libnpp \
      --enable-libopenjpeg \
      --enable-libopenmpt \
      --enable-libopus \
      --enable-libpulse \
      --enable-librsvg \
      --enable-librubberband \
      --enable-libshine \
      --enable-libsnappy \
      --enable-libsoxr \
      --enable-libspeex \
      --enable-libssh \
      --enable-libtheora \
      --enable-libtwolame \
      --enable-libvidstab \
      --enable-libvorbis \
      --enable-libvpx \
      --enable-libwebp \
      --enable-libx265 \
      --enable-libxml2 \
      --enable-libxvid \
      --enable-libzmq \
      --enable-libzvbi \
      --enable-lv2 \
      --enable-openal \
      --enable-opencl \
      --enable-opengl \
      --enable-sdl2 \
      --enable-libdc1394 \
      --enable-libdrm \
      --enable-libiec61883 \
      --enable-nvenc \
      --enable-frei0r \
      --enable-libx264 \
      --enable-libmfx \
      --enable-libfdk-aac \
      --enable-libzimg  \
      --enable-cuda-nvcc \
      --disable-shared \
      --enable-static \
      --enable-pthreads \
      --disable-stripping \
      --disable-ffplay && \
    make -j$(nproc) && \
    make -j$(nproc) install && \
    cd ..

FROM nvidia/cuda:11.6.0-base-ubuntu20.04

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libaom0 \
    libasound2 \
    libass9 \
    libavc1394-0 \
    libbluray2 \
    libbs2b0 \
    libcaca0 \
    libcdio-cdda2 \
    libcdio-paranoia2 \
    libcdio18 \
    libcodec2-0.9 \
    libdc1394-25 \
    libdrm2 \
    libfdk-aac1 \
    libfontconfig1 \
    libfreetype6 \
    libfribidi0 \
    libgl1 \
    libgme0 \
    libgnutls30 \
    libgsm1 \
    libiec61883-0 \
    libjack0 \
    liblilv-0-0 \
    liblzma5 \
    libmfx1 \
    libmp3lame0 \
    libmysofa1 \
    libnpp-11-6 \
    libnuma1 \
    libogg0 \
    libopenal1 \
    libopenal1 \
    libopenjp2-7 \
    libopenmpt0 \
    libopus0 \
    libpulse0 \
    librsvg2-common \
    librubberband2 \
    libsdl2-2.0-0 \
    libshine3 \
    libsnappy1v5 \
    libsoxr0 \
    libspeex1 \
    libssh-4 \
    libtheora0 \
    libtwolame0 \
    libunistring2 \
    libva2 \
    libva-drm2 \
    libva-x11-2 \
    libvdpau1 \
    libvidstab1.1 \
    libvorbis0a \
    libvpx6 \
    libwavpack1 \
    libwebp6 \
    libwebpmux3 \
    libx264-155 \
    libx265-179 \
    libxcb-shape0 \
    libxcb-shm0 \
    libxcb-xfixes0 \
    libxcb1 \
    libxml2 \
    libxv1 \
    libzvbi0 \
    libxvidcore4 \
    libzmq5 \
    ocl-icd-libopencl1 \
    zlib1g 

COPY --from=builder /ffmpeg-bin/ffmpeg /ffmpeg-bin/ffprobe /usr/local/bin/

VOLUME /workspace
WORKDIR /workspace
CMD /usr/local/bin/ffmpeg
