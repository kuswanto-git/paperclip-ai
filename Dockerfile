FROM node:20-alpine

RUN apk add --no-cache git bash

WORKDIR /app

RUN git clone --depth 1 https://github.com/agencyenterprise/paperclip-ai.git .

RUN echo "========== ROOT =========="
RUN ls -lah

RUN echo "========== PACKAGE.JSON =========="
RUN find . -name package.json

RUN echo "========== DIST =========="
RUN find . -name dist

RUN echo "========== INDEX =========="
RUN find . -name index.js

CMD ["sleep","3600"]
