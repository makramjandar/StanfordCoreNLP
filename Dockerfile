FROM alpine:3.8 as builder
MAINTAINER Makram Jandar <makramjandar@gmail.com>

RUN apk update \
    && apk add git wget openjdk8-jre-base py2-pip py2-curl \
    && pip install setuptools

WORKDIR /opt

# install geturl script to retrieve the most current download URL of CoreNLP
RUN git clone https://github.com/arne-cl/grepurl.git \
    && python /grepurl/setup.py install \
    # install latest CoreNLP release
    && wget $(grepurl -r 'zip$' -a http://stanfordnlp.github.io/CoreNLP/) \
    && unzip stanford-corenlp-full-*.zip \
    && mv $(ls -d stanford-corenlp-full-*/) corenlp \
    && rm *.zip \
    # install latest English language model
    && wget -P /opt/corenlp $(grepurl -r 'english.*jar$' -a http://stanfordnlp.github.io/CoreNLP | head -n 1)

---

# only keep the things we need to run and test CoreNLP
FROM alpine:3.8

RUN apk update && apk add openjdk8-jre-base
WORKDIR /opt/corenlp
COPY --from=builder /opt/corenlp .
ADD mj.jks .
EXPOSE 443

CMD java -mx4g -cp "*" edu.stanford.nlp.pipeline.StanfordCoreNLPServer --ssl true --key mj.jks --port 443 --timeout 15000
