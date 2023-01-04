# Build the daemon
FROM ghcr.io/kizzycode/buildbase-rust:alpine AS buildenv

RUN mv /root/.cargo /root/.cargo-persistent
RUN --mount=type=tmpfs,target=/root/.cargo \
    cp -a /root/.cargo-persistent/. /root/.cargo \
    && cargo install --git https://github.com/KizzyCode/FeedMe-rust --bins feedme-ytdlp \
    && cargo install --git https://github.com/KizzyCode/FeedMe-rust --bins feedme-feed \
    && cp /root/.cargo/bin/feedme-* /root/ \
    && cp -a /root/.cargo/. /root/.cargo-persistent
RUN rm -rf /root/.cargo \
    && mv /root/.cargo-persistent /root/.cargo


# Build the real container
FROM alpine:latest

RUN apk add --no-cache aria2 ffmpeg thttpd yt-dlp
RUN adduser --system --disabled-password --shell=/bin/sh --home=/home/feedme --uid=1000 feedme

COPY --from=buildenv /root/feedme-* /usr/bin/
COPY files/thttpd.conf /etc/thttpd.conf

# Configure feedme userdata
USER feedme
COPY files/yt-dlp.conf /home/feedme/.config/yt-dlp/config
RUN mkdir -p /home/feedme/.tmp.yt-dlp
RUN mkdir -p /home/feedme/webroot

CMD ["/usr/sbin/thttpd", "-D", "-C", "/etc/thttpd.conf"]
