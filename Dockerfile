# Build the daemon
FROM debian:stable-slim AS buildenv

ENV APT_PACKAGES build-essential ca-certificates curl git
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
    && apt-get upgrade --yes \
    && apt-get install --yes --no-install-recommends ${APT_PACKAGES}

RUN useradd --system --uid=10000 rust
USER rust
WORKDIR /home/rust/

RUN curl --tlsv1.3 --output rustup.sh https://sh.rustup.rs \
    && sh rustup.sh -y --profile minimal
COPY --chown=rust:rust ./ ws2812b.cgi/
RUN git clone https://github.com/KizzyCode/FeedMe-rust \
    && .cargo/bin/cargo install --path=FeedMe-rust/manual \
    && .cargo/bin/cargo install --path=FeedMe-rust/ytdlp \
    && .cargo/bin/cargo install --path=FeedMe-rust/feed


# Build the real container
FROM debian:stable-slim

ENV APT_PACKAGES aria2 ca-certificates ffmpeg nano nginx nodejs python3-pip
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
    && apt-get upgrade --yes \
    && apt-get install --yes --no-install-recommends ${APT_PACKAGES} \
    && apt-get clean

RUN pip install --break-system-packages "yt-dlp[default]"
RUN ln -sf /bin/bash /bin/sh

COPY --from=buildenv --chown=root:root /home/rust/.cargo/bin/feedme-* /usr/bin/
COPY ./files/nginx.conf /etc/nginx/nginx.conf
COPY ./files/nginx.conf /etc/nginx/nginx.conf

RUN groupadd --system feedme
RUN useradd --system --shell=/bin/sh --home=/home/feedme --uid=10000 --gid=feedme feedme
RUN touch /run/nginx.pid \
    && chown -R feedme /var/lib/nginx /usr/share/nginx /run/nginx.pid

USER feedme
COPY --chown=feedme:feedme ./files/yt-dlp.conf /home/feedme/.config/yt-dlp/config
RUN mkdir -p /home/feedme/.tmp.yt-dlp /home/feedme/webroot

WORKDIR /home/feedme/webroot
CMD ["/usr/sbin/nginx", "-e", "/dev/stderr", "-c", "/etc/nginx/nginx.conf"]
