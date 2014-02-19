'''
Created on 30/01/2014

@author: Jose Antonio Sal y Rosas Celi
'''

import sys
import os
import time
from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler
import traceback
from datetime import datetime
import ConfigParser
from util.commands import Commands


class MyHandler(PatternMatchingEventHandler):
    patterns=["*.PO", "*.po"]

    def process(self, event):
        user_to_notify, name_log_file, project_folder = self.read_config()
        
        bin_path = os.path.join(project_folder,"bin")
        log_path = os.path.join(project_folder,"log")
        
        if self.check_complete_file(event.src_path):
        
            command_for_reading = self.read_file(bin_path, event.src_path)
            dict_result = self.execute_commands(command_for_reading)
        
            if dict_result["result"] and dict_result["message"] == "":
                content_alert = "Archivo registrado exitosamente: %s" % event.src_path
            else:
                #print dict_result["message"]
                content_alert = "Error al ingresar el archivo: %s" % event.src_path
                command_alert = self.send_message(bin_path, user_to_notify, content_alert)
                result_alert = self.execute_commands(command_alert)
                print result_alert["message"]
                
            self.register_log(log_path, name_log_file, content_alert)
        
        else:
            print "Error revisando el archivo"
    
    def execute_commands(self, command):
        obj_cmmd = Commands()
        obj_cmmd.execute_command(command)
        return obj_cmmd.get_final_result()
    
    def read_file(self, bin_path, path_to_file):
        command = "projectsaga"
        main_launcher = os.path.join(bin_path, command)
        
        full_command = '%s "%s"' % (main_launcher, path_to_file)
        
        return full_command
    
    def send_message(self, bin_path, user_to_notify, content):
        command = "enviar_mensaje"
        launcher = os.path.join(bin_path, command)
        #print content_alert
        full_command = '%s "%s" "%s"' % (launcher, user_to_notify, content)
        
        return full_command
    
    def check_complete_file(self, path_to_file):
        try:
            with open(path_to_file, "r") as fileObj:
                read_data = fileObj.read()
                if not read_data:
                    time.sleep(15)
            fileObj.close()
            
            return True
        
        except IOError as ioe:
            print str(ioe)
            return False
    
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