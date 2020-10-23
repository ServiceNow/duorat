FROM pytorch/pytorch:1.6.0-cuda10.1-cudnn7-devel

WORKDIR /app
ENV PYTHONPATH=/app

RUN apt-get update && \
    apt-get install -y git wget unzip && \
    apt-get clean;

# Install OpenJDK-8
RUN apt-get update && \
    apt-get install -y openjdk-8-jdk && \
    apt-get install -y ant && \
    apt-get clean;

# Fix certificate issues
RUN apt-get update && \
    apt-get install ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f;

# Setup JAVA_HOME -- useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME

COPY Pipfile Pipfile.lock ./
ENV PIP_NO_INPUT=1
RUN pip install pipenv==2020.8.13
RUN pipenv install --dev --system \
    && rm -rf /root/.cache/pip*

RUN python -m nltk.downloader -d /usr/local/share/nltk_data punkt stopwords

RUN mkdir /corenlp; cd /corenlp;\
    wget -nv http://nlp.stanford.edu/software/stanford-corenlp-full-2018-10-05.zip;\
    unzip stanford-corenlp-full-2018-10-05.zip;\
    rm stanford-corenlp-full-2018-10-05.zip

COPY . /app


ENV CACHE_DIR /logdir
ENV TRANSFORMERS_CACHE /logdir
