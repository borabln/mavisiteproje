FROM postgres:15-alpine

ENV POSTGRES_USER=borabln
ENV POSTGRES_PASSWORD=20333039362aA_
ENV POSTGRES_DB=mavisiteproje

COPY init.sql /docker-entrypoint-initdb.d/

EXPOSE 5432