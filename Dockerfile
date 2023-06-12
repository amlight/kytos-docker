FROM debian:bullseye-slim
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
ARG branch_flow_stats=master
ARG branch_sdntrace_cp=master
ARG branch_of_multi_table=master
# USAGE: ... --build-arg release_ui=download/2022.2.0 ...
ARG release_ui=latest/download

RUN apt-get update && apt-get install -y --no-install-recommends \
	python3-setuptools python3-pip rsyslog iproute2 procps curl jq git-core patch \
        openvswitch-switch mininet iputils-ping vim tmux less \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN sed -i '/imklog/ s/^/#/' /etc/rsyslog.conf

RUN git config --global url."https://github.com".insteadOf git://github.com

RUN python3 -m pip install setuptools==60.2.0
RUN python3 -m pip install pip==21.3.1
RUN python3 -m pip install wheel==0.37.1

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
 && python3 -m pip install -e git+https://github.com/kytos-ng/flow_stats@${branch_flow_stats}#egg=amlight-flow_stats \
 && python3 -m pip install -e git+https://github.com/kytos-ng/sdntrace_cp@${branch_sdntrace_cp}#egg=amlight-sdntrace_cp \
 && python3 -m pip install -e git+https://github.com/kytos-ng/mef_eline@${branch_mef_eline}#egg=kytos-mef_eline \
 && python3 -m pip install -e git+https://github.com/kytos-ng/of_multi_table@${branch_of_multi_table}#egg=kytos-of_multi_table \
 && curl -L -o /tmp/latest.zip https://github.com/kytos-ng/ui/releases/${release_ui}/latest.zip \
 && python3 -m zipfile -e /tmp/latest.zip  /usr/local/lib/python3.9/dist-packages/kytos/web-ui \
 && rm -f /tmp/latest.zip

# end-to-end python related dependencies
# pymongo and requests resolve to the same version on kytos and NApps
RUN python3 -m pip install pytest-timeout==2.1.0 \
 && python3 -m pip install pytest==7.2.0 \
 && python3 -m pip install pytest-rerunfailures==10.2 \
 && python3 -m pip install mock==4.0.3 \
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
