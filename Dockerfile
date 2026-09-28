FROM node:22-alpine

RUN apk add --no-cache python3 build-base \
    && npm install -g n8n \
    && rm -rf /var/cache/apk/* /var/tmp/*

USER node
ENV N8N_HOME=/home/node
WORKDIR /home/node
ENTRYPOINT ["n8n"]