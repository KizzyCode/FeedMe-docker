# Build the daemon
FROM alpine:latest AS buildenv

RUN apk add --no-cache build-base cargo git
RUN cargo install --git https://github.com/KizzyCode/FeedMe-rust --bins feedme-ytdlp
RUN cargo install --git https://github.com/KizzyCode/FeedMe-rust --bins feedme-feed


# Build the real container
FROM alpine:latest

RUN apk add --no-cache aria2 ffmpeg thttpd py3-pip
RUN pip install yt-dlp
RUN adduser --system --disabled-password --shell=/bin/sh --home=/home/feedme --uid=1000 feedme

COPY --from=buildenv /root/feedme-* /usr/bin/
COPY files/thttpd.conf /etc/thttpd.conf

# Configure feedme userdata
USER feedme
COPY files/yt-dlp.conf /home/feedme/.config/yt-dlp/config
RUN mkdir -p /home/feedme/.tmp.yt-dlp
RUN mkdir -p /home/feedme/webroot

CMD ["/usr/sbin/thttpd", "-D", "-C", "/etc/thttpd.conf"]
