# Stage 1: build Kytos UI
FROM node:lts-alpine as ui-builder

ARG branch_ui=master

WORKDIR /app

RUN apk add --no-cache git

RUN git clone -b ${branch_ui} --single-branch https://github.com/kytos-ng/ui \
 && cd ui \
 && sed -ri 's/"version": "[^"]+"/"version": "Commit-'$(git log -1 --pretty=format:%h)'"/g' ./package.json \
 && npm install \
 && npm run build

# Stage 2: build Kytos
FROM debian:bookworm-slim
MAINTAINER Italo Valcy <italovalcy@gmail.com>

ARG branch_python_openflow=master
ARG branch_kytos_utils=master
ARG branch_kytos=master
ARG branch_of_core=master
ARG branch_flow_manager=master
ARG branch_topology=master
ARG branch_of_lldp=master
ARG branch_pathfinder=master
ARG branch_mef_eline=master
ARG branch_maintenance=master
ARG branch_coloring=master
ARG branch_sdntrace=master
ARG branch_kytos_stats=master
ARG branch_sdntrace_cp=master
ARG branch_of_multi_table=master
ARG branch_kafka_events=master

RUN apt-get update && apt-get install -y --no-install-recommends \
	python3-setuptools python3-pip orphan-sysvinit-scripts rsyslog iproute2 procps curl jq git-core patch \
        openvswitch-switch mininet iputils-ping vim tmux less \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*
RUN rm /usr/lib/python3.11/EXTERNALLY-MANAGED
RUN sed -i '/imklog/ s/^/#/' /etc/rsyslog.conf

RUN git config --global url."https://github.com".insteadOf git://github.com

RUN python3 -m pip install setuptools==69.1.1
RUN python3 -m pip install pip==24.0
RUN python3 -m pip install wheel==0.42.0

RUN python3 -m pip install https://github.com/kytos-ng/python-openflow/archive/${branch_python_openflow}.zip \
 && python3 -m pip install https://github.com/kytos-ng/kytos-utils/archive/${branch_kytos_utils}.zip \
 && python3 -m pip install https://github.com/kytos-ng/kytos/archive/${branch_kytos}.zip

RUN python3 -m pip install -e git+https://github.com/kytos-ng/of_core@${branch_of_core}#egg=kytos-of_core \
 && python3 -m pip install -e git+https://github.com/kytos-ng/flow_manager@${branch_flow_manager}#egg=kytos-flow_manager \
 && python3 -m pip install -e git+https://github.com/kytos-ng/topology@${branch_topology}#egg=kytos-topology \
 && python3 -m pip install -e git+https://github.com/kytos-ng/of_lldp@${branch_of_lldp}#egg=kytos-of_lldp \
 && python3 -m pip install -e git+https://github.com/kytos-ng/pathfinder@${branch_pathfinder}#egg=kytos-pathfinder \
 && python3 -m pip install -e git+https://github.com/kytos-ng/maintenance@${branch_maintenance}#egg=kytos-maintenance \
 && python3 -m pip install -e git+https://github.com/kytos-ng/coloring@${branch_coloring}#egg=amlight-coloring \
 && python3 -m pip install -e git+https://github.com/kytos-ng/sdntrace@${branch_sdntrace}#egg=amlight-sdntrace \
 && python3 -m pip install -e git+https://github.com/kytos-ng/kytos_stats@${branch_kytos_stats}#egg=amlight-kytos_stats \
 && python3 -m pip install -e git+https://github.com/kytos-ng/sdntrace_cp@${branch_sdntrace_cp}#egg=amlight-sdntrace_cp \
 && python3 -m pip install -e git+https://github.com/kytos-ng/mef_eline@${branch_mef_eline}#egg=kytos-mef_eline \
 && python3 -m pip install -e git+https://github.com/kytos-ng/of_multi_table@${branch_of_multi_table}#egg=kytos-of_multi_table \
 && python3 -m pip install -e git+https://github.com/kytos-ng/kafka_events@${branch_kafka_events}#egg=kytos-kafka_events

COPY --from=ui-builder /app/ui/web-ui /usr/local/lib/python3.11/dist-packages/kytos/web-ui

# end-to-end python related dependencies
# pymongo and requests resolve to the same version on kytos and NApps
RUN python3 -m pip install pytest-timeout==2.2.0 \
 && python3 -m pip install pytest==8.1.1 \
 && python3 -m pip install pytest-asyncio==1.1.0 \
 && python3 -m pip install pytest-rerunfailures==13.0 \
 && python3 -m pip install mock==5.1.0 \
 && python3 -m pip install pymongo \
 && python3 -m pip install requests

COPY ./apply-patches.sh  /tmp/
COPY ./patches /tmp/patches

RUN cd /tmp && ./apply-patches.sh && rm -rf /tmp/*

WORKDIR /
COPY docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 6653
EXPOSE 8181

ENTRYPOINT ["/docker-entrypoint.sh"]
