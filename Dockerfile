FROM python:3.7

ENV VERSION 2.1692-vsc1.39.2
ENV DOMAIN localhost
ENV DOCKER_VERSION 18.09.2

COPY docker-entrypoint_docker.sh /docker-entrypoint.sh

RUN apt update \
    && apt install net-tools -y \
    && apt-get clean \
    && wget https://github.com/cdr/code-server/releases/download/${VERSION}/code-server${VERSION}-linux-x86_64.tar.gz \
    && tar -xzf code-server${VERSION}-linux-x86_64.tar.gz \
    && mv code-server${VERSION}-linux-x86_64/code-server /usr/local/bin/code-server \
    && chmod +x /usr/local/bin/code-server /docker-entrypoint.sh \
    && rm -rf code-server${VERSION}-linux-x86_64.tar.gz

RUN mkdir /certs && cd /certs \
    && export PASSPHRASE=$(head -c 500 /dev/urandom | tr -dc a-z0-9A-Z | head -c 128; echo) \
    && openssl genrsa -des3 -out $DOMAIN.key -passout env:PASSPHRASE 2048 \
    && export subj='/C=ZA/ST=WC/O=Org/localityName=CT/commonName=localhost/organizationalUnitName=OrgUnit/emailAddress=root@localhost/' \
    && openssl req -new -batch -subj "${subj}" -key $DOMAIN.key -out $DOMAIN.csr -passin env:PASSPHRASE \
    && cp $DOMAIN.key $DOMAIN.key.org \
    && openssl rsa -in $DOMAIN.key.org -out $DOMAIN.key -passin env:PASSPHRASE \
    && openssl x509 -req -days 3650 -in $DOMAIN.csr -signkey $DOMAIN.key -out $DOMAIN.crt

ADD ./code/ /code

CMD ["/docker-entrypoint.sh"]
