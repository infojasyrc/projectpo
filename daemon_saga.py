#!/home/dev/.pyenv/versions/appsaga/bin/python

'''
Created on Mar 3, 2014

@author: Jose Antonio Sal y Rosas Celi
'''

import time
from watchdog.observers import Observer
from projectsaga import MyHandler
from config import Config

from daemon import runner


class DaemonSagaPO():
    ''' This class runs as a daemon'''
   
    def __init__(self):
        '''The constructor set the main parameters to convert this class to a daemon.'''
        self.stdin_path = '/dev/null'
        self.stdout_path = '/dev/tty'
        self.stderr_path = '/dev/tty'
        self.pidfile_path =  '/var/run/saga_po/saga_po.pid'
        self.pidfile_timeout = 5
           
    def run(self):
        '''This function get the path to observed and execute the watchdog class.'''
        config_file = Config()
        path_to_watch = config_file.get_path_to_watch()
        
        while True:
            observer = Observer()
            observer.schedule(MyHandler(), path_to_watch)
            observer.start()
        
            try:
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                observer.stop()
        
            observer.join()
            

if __name__ == '__main__':
    app = DaemonSagaPO()
    
    daemon_runner = runner.DaemonRunner(app)
    daemon_runner.do_action()
