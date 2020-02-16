FROM node:12.15.0-stretch

RUN apt update
RUN apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

# Yarn for installing node packages
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# All the necessary packages for XOA
RUN apt install -y yarn build-essential redis-server libpng-dev git python-minimal libvhdi-utils lvm2 cifs-utils

# Fetch the code
RUN git clone -b master http://github.com/vatesfr/xen-orchestra /etc/xen-orchestra

WORKDIR /etc/xen-orchestra

# Install dependencies
RUN yarn && yarn build

# Install plugins
RUN find /etc/xen-orchestra/packages/ -maxdepth 1 -mindepth 1 -not -name "xo-server" -not -name "xo-web" -not -name "xo-server-cloud" -exec ln -s {} /etc/xen-orchestra/packages/xo-server/node_modules \;
RUN yarn && yarn build

# # Fix path for xo-web content in xo-server configuration
RUN sed -i "s/#'\/' = '\/path\/to\/xo-web\/dist\//'\/' = '..\/xo-web\/dist\//" /etc/xen-orchestra/packages/xo-server/sample.config.toml

# # Move edited config sample to place
RUN mv /etc/xen-orchestra/packages/xo-server/sample.config.toml /etc/xen-orchestra/packages/xo-server/.xo-server.toml

# # # Install forever for starting/stopping Xen-Orchestra
# # RUN npm install forever -g

# # # Logging
# # RUN ln -sf /proc/1/fd/1 /var/log/redis/redis.log
# # RUN ln -sf /proc/1/fd/1 /var/log/xo-server.log

# # # Healthcheck
# # ADD healthcheck.sh /healthcheck.sh
# # RUN chmod +x /healthcheck.sh
# # HEALTHCHECK --start-period=1m --interval=30s --timeout=5s --retries=2 CMD /healthcheck.sh

WORKDIR /etc/xen-orchestra/packages/xo-server

EXPOSE 80

CMD /usr/bin/redis-server /etc/redis/redis.conf --daemonize yes; yarn start