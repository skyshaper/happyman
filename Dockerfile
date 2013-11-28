FROM ubuntu:12.04
RUN apt-get update 
RUN apt-get -y dist-upgrade 

RUN apt-get install -y build-essential wget
RUN cd /tmp && wget http://www.cpan.org/src/5.0/perl-5.18.1.tar.gz && tar xf perl-5.18.1.tar.gz
RUN cd /tmp/perl-5.18.1 && ./Configure -des && make && make install

RUN apt-get install -y python python-dev python-setuptools
RUN easy_install virtualenv

ADD . /opt/happyman

RUN apt-get install -y libssl-dev openssl
RUN cd /opt/happyman && ./vendor/bin/carton install --cached --deployment --without develop,test

RUN virtualenv /opt/happyman/python/virtualenv
RUN /opt/happyman/python/virtualenv/bin/pip install --no-index --find-links=/opt/happyman/python/vendor/cache/ -r /opt/happyman/python/requirements_lock.txt

VOLUME ["/data"]
RUN ln -s /data/happyman.conf /opt/happyman/happyman.conf
RUN ln -s /data/cobe.sqlite /opt/happyman/cobe.sqlite 

CMD cd /opt/happyman && ./vendor/bin/carton exec ./happyman