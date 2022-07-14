FROM jiyecafe/wechat-devtools-build:v3 

WORKDIR /workspace

ADD docker /workspace/docker
ADD tools /workspace/tools
ADD conf /workspace/conf
ADD bin /workspace/bin

RUN ./docker/docker-entrypoint

RUN apt-get install -yq --no-install-recommends \
	libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 \
	libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 \
	libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 \
	libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcursor1 libxdamage1 libxext6 \
	libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 libnss3 libgl1-mesa-glx

RUN ln -sf /var/lib/dbus/machine-id /etc/machine-id

CMD ./bin/wechat-devtools
