FROM debian:buster-slim
MAINTAINER Italo Valcy <italovalcy@gmail.com>

ARG branch_python_openflow=master
ARG branch_kytos_utils=master
ARG branch_kytos=master
ARG branch_storehouse=master
ARG branch_of_core=master
ARG branch_flow_manager=master
ARG branch_topology=master
ARG branch_of_lldp=master
ARG branch_pathfinder=master
ARG branch_mef_eline=master
ARG branch_maintenance=master
ARG branch_coloring=master
ARG branch_sdntrace=master
ARG branch_scheduler=master
ARG branch_flow_stats=master
ARG branch_sdntrace_cp=master

RUN apt-get update && apt-get install -y --no-install-recommends \
	python3-setuptools python3-pip rsyslog iproute2 procps curl jq git-core patch \
        openvswitch-switch mininet iputils-ping vim tmux less \
        python-pytest python-requests python-mock python-pytest-timeout \
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

RUN python3 -m pip install -e git+https://github.com/kytos-ng/storehouse@${branch_storehouse}#egg=kytos-storehouse \
 && python3 -m pip install -e git+https://github.com/kytos-ng/of_core@${branch_of_core}#egg=kytos-of_core \
 && python3 -m pip install -e git+https://github.com/kytos-ng/flow_manager@${branch_flow_manager}#egg=kytos-flow_manager \
 && python3 -m pip install -e git+https://github.com/kytos-ng/topology@${branch_topology}#egg=kytos-topology \
 && python3 -m pip install -e git+https://github.com/kytos-ng/of_lldp@${branch_of_lldp}#egg=kytos-of_lldp \
 && python3 -m pip install -e git+https://github.com/kytos-ng/pathfinder@${branch_pathfinder}#egg=kytos-pathfinder \
 && python3 -m pip install -e git+https://github.com/kytos-ng/mef_eline@${branch_mef_eline}#egg=kytos-mef_eline \
 && python3 -m pip install -e git+https://github.com/kytos-ng/maintenance@${branch_maintenance}#egg=kytos-maintenance \
 && python3 -m pip install -e git+https://github.com/amlight/coloring@${branch_coloring}#egg=amlight-coloring \
 && python3 -m pip install -e git+https://github.com/amlight/sdntrace@${branch_sdntrace}#egg=amlight-sdntrace \
 && python3 -m pip install -e git+https://github.com/amlight/scheduler@${branch_scheduler}#egg=amlight-scheduler \
 && python3 -m pip install -e git+https://github.com/amlight/flow_stats@${branch_flow_stats}#egg=amlight-flow_stats \
 && python3 -m pip install -e git+https://github.com/amlight/sdntrace_cp@${branch_sdntrace_cp}#egg=amlight-sdntrace_cp

# disable sdntrace and sdntrace_cp by default (along with their deps), you can enable them again by running:
#	kytos napps enable amlight/sdntrace
# 	kytos napps enable amlight/sdntrace_cp
RUN unlink /var/lib/kytos/napps/amlight/coloring
RUN unlink /var/lib/kytos/napps/amlight/sdntrace
RUN unlink /var/lib/kytos/napps/amlight/scheduler
RUN unlink /var/lib/kytos/napps/amlight/flow_stats
RUN unlink /var/lib/kytos/napps/amlight/sdntrace_cp

COPY ./apply-patches.sh  /tmp/
COPY ./patches /tmp/patches

RUN cd /tmp && ./apply-patches.sh && rm -rf /tmp/*

WORKDIR /
COPY docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 6653
EXPOSE 8181

ENTRYPOINT ["/docker-entrypoint.sh"]
