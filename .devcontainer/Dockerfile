FROM python:3

ARG CONFIG_DIR="/root/.jupyter"
ARG CONFIG_FILE="${CONFIG_DIR}/jupyter_server_config.py"

RUN apt update \
&& apt install sshpass \
&& pip install \
ansible \
ansible-runner \
jupyterlab \
jupyterlab-git \
&& test -d ${CONFIG_DIR} || mkdir ${CONFIG_DIR} \
&& test -f ${CONFIG_FILE} || touch ${CONFIG_FILE} \
&& echo "c.ServerApp.allow_origin = '*'" >> ${CONFIG_FILE} \
&& echo "c.NotebookApp.allow_origin = '*'" >> ${CONFIG_FILE} \
&& echo "c.ServerApp.allow_root = True " >> ${CONFIG_FILE}

CMD [ "/bin/bash","-c","tail -f /dev/null" ]
