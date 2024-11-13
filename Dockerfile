# Build the daemon
FROM debian:stable-slim AS buildenv

ENV APT_PACKAGES build-essential ca-certificates curl git
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
    && apt-get upgrade --yes \
    && apt-get install --yes --no-install-recommends ${APT_PACKAGES}

RUN curl --tlsv1.3 --output rustup.sh https://sh.rustup.rs \
    && sh rustup.sh -y
RUN git clone https://github.com/KizzyCode/FeedMe-rust \
    && /root/.cargo/bin/cargo install --path=FeedMe-rust/manual \
    && /root/.cargo/bin/cargo install --path=FeedMe-rust/ytdlp \
    && /root/.cargo/bin/cargo install --path=FeedMe-rust/feed


# Build the real container
FROM debian:stable-slim

ENV APT_PACKAGES aria2 ca-certificates ffmpeg nano nginx python3-pip
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
    && apt-get upgrade --yes \
    && apt-get install --yes --no-install-recommends ${APT_PACKAGES} \
    && apt-get clean

RUN pip install --break-system-packages yt-dlp
RUN ln -sf /bin/bash /bin/sh

COPY --from=buildenv /root/.cargo/bin/feedme-* /usr/bin/
COPY ./files/nginx.conf /etc/nginx/nginx.conf
COPY ./files/nginx.conf /etc/nginx/nginx.conf

RUN addgroup --system feedme
RUN adduser --system --disabled-password --shell=/bin/sh --home=/home/feedme --uid=10000 --ingroup=feedme feedme
RUN touch /run/nginx.pid \
    && chown -R feedme /var/lib/nginx /usr/share/nginx /run/nginx.pid

USER feedme
COPY ./files/yt-dlp.conf /home/feedme/.config/yt-dlp/config
RUN mkdir -p /home/feedme/.tmp.yt-dlp /home/feedme/webroot

WORKDIR /home/feedme/webroot
CMD ["/usr/sbin/nginx", "-e", "/dev/stderr", "-c", "/etc/nginx/nginx.conf"]
