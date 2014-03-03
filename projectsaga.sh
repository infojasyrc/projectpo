 #! /bin/bash
# Copyright (c) 1996-2012 My Company.
# All rights reserved.
#
# Author: Bob Bobson, 2012
#
# Please send feedback to bob@bob.com
#
# /etc/init.d/testdaemon
#
### BEGIN INIT INFO
# Provides: testdaemon
# Required-Start:
# Should-Start:
# Required-Stop:
# Should-Stop:
# Default-Start:  3 5
# Default-Stop:   0 1 2 6
# Short-Description: Test daemon process
# Description:    Runs up the test daemon process
### END INIT INFO

DIR=/home/dev/CodeTyphonProjects/projectpo
DAEMON=$DIR/daemon_saga.py
DAEMON_NAME=daemon_saga

# Activate the python virtual environment
    . /home/dev/.pyenv/versions/appsaga/bin/activate

case "$1" in
  start)
    echo "Starting server"
    # Start the daemon
    python $DAEMON start
    ;;
  stop)
    echo "Stopping server"
    # Stop the daemon
    python $DAEMON stop
    ;;
  restart)
    echo "Restarting server"
    python $DAEMON restart
    ;;
  *)
    # Refuse to do other stuff
    echo "Usage: /etc/init.d/testdaemon.sh {start|stop|restart}"
    exit 1
    ;;
esac

exit 0