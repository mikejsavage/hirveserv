FROM alpine
RUN apk update && apk upgrade

RUN apk add lua5.4 lua5.4-dev luarocks5.4 gcc git make musl-dev libev libev-dev
RUN luarocks-5.4 install arc4random
RUN luarocks-5.4 install bcrypt
RUN luarocks-5.4 install lpeg
RUN luarocks-5.4 install lua-cjson
RUN luarocks-5.4 install https://luarocks.org/manifests/brimworks/lua-ev-scm-1.rockspec
RUN luarocks-5.4 install luafilesystem
RUN luarocks-5.4 install luasocket

RUN echo "auth = true" > /etc/hirveserv.conf
RUN echo "dataDir = \"/hirveserv\"" >> /etc/hirveserv.conf

EXPOSE 4050
VOLUME /hirveserv
WORKDIR /hirveserv
COPY hirveserv /usr/bin
ENTRYPOINT [ "/usr/bin/lua5.4", "/usr/bin/hirveserv", "/etc/hirveserv.conf" ]
