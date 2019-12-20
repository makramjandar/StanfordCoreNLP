FROM alpine:3.8 as builder
MAINTAINER Makram Jandar <makramjandar@gmail.com>

RUN apk update \
    && apk add git wget openjdk8-jre-base py2-pip py2-curl \
    && pip install setuptools

# install geturl script to retrieve the most current download URL of CoreNLP
WORKDIR /opt
RUN git clone https://github.com/arne-cl/grepurl.git
WORKDIR /opt/grepurl
RUN python setup.py install

# install latest CoreNLP release
WORKDIR /opt
RUN wget $(grepurl -r 'zip$' -a http://stanfordnlp.github.io/CoreNLP/) && \
    unzip stanford-corenlp-full-*.zip && \
    mv $(ls -d stanford-corenlp-full-*/) corenlp && rm *.zip
    
# install latest English language model    
WORKDIR /opt/corenlp
RUN wget $(grepurl -r 'english.*jar$' -a http://stanfordnlp.github.io/CoreNLP | head -n 1)

# ---

# only keep the things we need to run and test CoreNLP
FROM alpine:3.8

RUN apk update && apk add openjdk8-jre-base
WORKDIR /opt/corenlp
COPY --from=builder /opt/corenlp .
ADD keystore.jks .
RUN chmod 444 keystore.jks
EXPOSE 8443

CMD java -mx4g -cp "*" edu.stanford.nlp.pipeline.StanfordCoreNLPServer --ssl true --key keystore.jks --port 8443 --timeout 15000
