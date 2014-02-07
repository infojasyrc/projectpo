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

class MyHandler(PatternMatchingEventHandler):
    patterns=["*.PO", "*.po"]

    def process(self, event):
        user_to_notify = "Oscar"
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
                # print content_alert
                full_command_alert = '%s "%s" "%s"' % (launcher_alert, user_to_notify, content_alert)
                
                Popen(full_command_alert, shell=True, stdin=PIPE, stdout=PIPE, stderr=STDOUT, close_fds=True)
                
            else:
                print "Error al ingresar el archivo: %s" % event.src_path
            
        except CalledProcessError:
            err = traceback.format_exception(sys.exc_info()[0],sys.exc_info()[1],sys.exc_info()[2])
            print err

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