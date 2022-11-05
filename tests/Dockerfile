FROM debian:bullseye-slim

ARG WHAT_IN_THE_WORLD

RUN echo "Hello ${WHAT_IN_THE_WORLD}" > /root/message.txt

ENTRYPOINT ["cat", "/root/message.txt"]