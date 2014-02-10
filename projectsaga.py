'''
Created on 30/01/2014

@author: Jose Antonio Sal y Rosas Celi
'''

import sys
import os
import time
from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler
from subprocess import Popen, CalledProcessError, PIPE, STDOUT
import traceback
import json
from datetime import datetime
import ConfigParser


class MyHandler(PatternMatchingEventHandler):
    patterns=["*.PO", "*.po"]

    def process(self, event):
        user_to_notify, name_log_file = self.read_config()
        
        path = os.path.dirname(__file__)
        command = "projectsaga"
        command_alert = "enviar_mensaje"
        
        launcher = os.path.join(path, command)
        launcher_alert = os.path.join(path, command_alert)
        
        full_command = '%s "%s"' % (launcher, event.src_path)
        
        try: 
            # Execute command
            p = Popen(full_command, shell=True, stdin=PIPE, stdout=PIPE, stderr=STDOUT, close_fds=True)
            # Get output
            rs_cmd = p.stdout.read()
            
            if rs_cmd=="":
                content_alert = "Archivo registrado exitosamente: %s" % event.src_path
                
            else:
                content_alert = "Error al ingresar el archivo: %s" % event.src_path
                #print content_alert
                full_command_alert = '%s "%s" "%s"' % (launcher_alert, user_to_notify, content_alert)
                
                Popen(full_command_alert, shell=True, stdin=PIPE, stdout=PIPE, stderr=STDOUT, close_fds=True)
            
            self.register_log(os.path.join(path, name_log_file), content_alert) 
            
        except CalledProcessError:
            err = traceback.format_exception(sys.exc_info()[0],sys.exc_info()[1],sys.exc_info()[2])
            print err
    
    def read_config(self):
        config_file = os.path.join(os.path.dirname(__file__),"config.ini")
        
        config = ConfigParser.ConfigParser()
        config.read(config_file)
        
        user_to_notify = str(config.get('basic', 'user'))
        name_log_file = str(config.get('basic','log'))
        
        return user_to_notify, name_log_file
    
    def register_log(self, log_file, content):
        realtime = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        new_content = "[%s] %s\n" % (realtime, content)
        
        if (os.path.exists(log_file) and os.path.isfile(log_file)):
            new_instance = open(log_file, "a")    
        else:
            new_instance = open(log_file, "w")
        
        new_instance.write(new_content)
        new_instance.close()
    
    def on_modified(self, event):
        pass

    def on_created(self, event):
        self.process(event)


if __name__ == '__main__':
    args = sys.argv[1:]
    observer = Observer()
    observer.schedule(MyHandler(), path=args[0] if args else '.')
    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()

    observer.join()