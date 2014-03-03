'''
Created on Jan 30, 2014

@author: Jose Antonio Sal y Rosas Celi
'''

import sys
import os
import time
from config import Config
import logging
from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler
from util.commands import Commands


class MyHandler(PatternMatchingEventHandler):
    project_folder = os.path.dirname(__file__)
    patterns=["*.PO", "*.po"]

    def process(self, event):
        basic_section = self.read_config()
        
        bin_path = os.path.join(self.project_folder,"bin")
        log_path = os.path.join(self.project_folder,"log")
        
        if self.check_complete_file(event.src_path):
        
            command_for_reading = self.read_file(bin_path, event.src_path)
            dict_result = self.execute_commands(command_for_reading)
        
            if dict_result["result"] and dict_result["message"] == "":
                content_alert = "Archivo registrado exitosamente: %s" % event.src_path
            else:
                content_alert = "Error al ingresar el archivo: %s" % event.src_path
                command_alert = self.send_message(bin_path, basic_section["user"], content_alert)
                result_alert = self.execute_commands(command_alert)
                content_alert += result_alert["message"]
                
            self.register_log(log_path, basic_section["log"], content_alert)
        
        else:
            content_alert = "Error revisando el archivo: %s" % event.src_path
            self.register_log(log_path, basic_section["log"], content_alert)
    
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
        config_file = Config()
        basic_section = config_file.get_basic_section()
        
        return basic_section
    
    def register_log(self, log_path, log_file, content):
        #final_log_file = os.path.join(log_path, log_file)
        final_log_file = "/var/log/saga_po/saga_po.log"
        
        logger = logging.getLogger("")
        logger.setLevel(logging.INFO)
        #formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
        formatter = logging.Formatter("%(asctime)s - %(message)s")
        #handler = logging.FileHandler("/var/log/saga_po/deamonsagapo.log")
        handler = logging.FileHandler(final_log_file)
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        logger.info(content)
        
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