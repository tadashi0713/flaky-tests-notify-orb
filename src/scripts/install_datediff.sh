#!/bin/bash -eu

wget https://bitbucket.org/hroptatyr/dateutils/downloads/dateutils-0.4.10.tar.xz
tar Jxfv dateutils-0.4.10.tar.xz
cd dateutils-0.4.10/
./configure
sudo make install
