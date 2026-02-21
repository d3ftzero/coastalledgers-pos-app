FROM alpine:3.14
LABEL maintainer="d3ftzero"

ADD tables.sql /docker-entrypoint-initdb.d/01-tables.sql
ADD constraints.sql /docker-entrypoint-initdb.d/02-constraints.sql
VOLUME /docker-entrypoint-initdb.d
