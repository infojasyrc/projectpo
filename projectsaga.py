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
from datetime import datetime
import ConfigParser


class MyHandler(PatternMatchingEventHandler):
    patterns=["*.PO", "*.po"]

    def process(self, event):
        user_to_notify, name_log_file, project_folder = self.read_config()
        
        bin_path = os.path.join(project_folder,"bin")
        main_command = "projectsaga"
        alert_command = "enviar_mensaje"
        
        main_launcher = os.path.join(bin_path, main_command)
        alert_launcher = os.path.join(bin_path, alert_command)
        
        full_command = '%s "%s"' % (main_launcher, event.src_path)
        
        log_path = os.path.join(project_folder,"log")
        
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
                full_command_alert = '%s "%s" "%s"' % (alert_launcher, user_to_notify, content_alert)
                
                Popen(full_command_alert, shell=True, stdin=PIPE, stdout=PIPE, stderr=STDOUT, close_fds=True)
            
            self.register_log(log_path, name_log_file, content_alert) 
            
        except CalledProcessError:
            err = traceback.format_exception(sys.exc_info()[0],sys.exc_info()[1],sys.exc_info()[2])
            print err
    
    def read_config(self):
        project_folder = os.path.dirname(__file__)
        
        config_file = os.path.join(project_folder,"bin","config.ini")
        
        config = ConfigParser.ConfigParser()
        config.read(config_file)
        
        user_to_notify = str(config.get('basic','user'))
        name_log_file = str(config.get('basic','log'))
        
        return user_to_notify, name_log_file, project_folder
    
    def register_log(self, log_path, log_file, content):
        final_log_file = os.path.join(log_path, log_file)
        
        realtime = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        new_content = "[%s] %s\n" % (realtime, content)
        
        try:
            if (os.path.isdir(log_path)):       
                if (os.path.exists(final_log_file) and os.path.isfile(final_log_file)):
                    new_instance = open(final_log_file, "a")    
                else:
                    new_instance = open(final_log_file, "w")
            else:
                os.mkdir(log_path)
                new_instance = open(final_log_file, "w")
        
            new_instance.write(new_content)
            new_instance.close()
        
        except IOError:
            print "Error al guardar el archivo"
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