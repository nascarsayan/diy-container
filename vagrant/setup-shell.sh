#!/bin/bash
# Optional: Set up tmux
[ -d /home/vagrant/init-linux ] || git clone https://github.com/nascarsayan/init-linux.git /home/vagrant/init-linux
bash /home/vagrant/init-linux/init.sh
