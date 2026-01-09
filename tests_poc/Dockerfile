FROM ubuntu:24.04

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    git \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /repo

ENTRYPOINT ["bash", "tests_poc/run.sh"]
