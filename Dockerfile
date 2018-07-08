FROM node:10-alpine

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install --only=production

COPY . .
ENTRYPOINT [ "npm", "test" ]
