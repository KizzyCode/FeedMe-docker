# Build the daemon
FROM alpine:latest AS buildenv

RUN apk add --no-cache build-base cargo git
RUN cargo install --git https://github.com/KizzyCode/FeedMe-rust --bins feedme-ytdlp
RUN cargo install --git https://github.com/KizzyCode/FeedMe-rust --bins feedme-feed


# Build the real container
FROM alpine:latest

RUN apk add --no-cache aria2 ffmpeg nano nginx py3-pip
RUN pip install --break-system-packages yt-dlp
COPY --from=buildenv /root/.cargo/bin/feedme-* /usr/bin/

RUN addgroup --system feedme
RUN adduser --system --disabled-password --shell=/bin/sh --home=/home/feedme --uid=1000 --ingroup=feedme feedme

COPY ./files/nginx.conf /etc/nginx/nginx.conf
RUN chown -R feedme /var/lib/nginx /run/nginx

USER feedme
COPY ./files/yt-dlp.conf /home/feedme/.config/yt-dlp/config
RUN mkdir -p /home/feedme/.tmp.yt-dlp
RUN mkdir -p /home/feedme/webroot

WORKDIR /home/feedme/webroot
CMD ["/usr/sbin/nginx", "-e", "/dev/stderr", "-c", "/etc/nginx/nginx.conf"]
