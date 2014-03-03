'''
Created on Mar 3, 2014

@author: dev
'''

import os
from config import Config
from util.commands import Commands


class ProcessFolder(object):
    
    def __init__(self):
        self.project_folder = os.path.dirname(__file__)

    def procesar(self):
        path = "/home/dev/Documents/Archivos_PO"
        
        for each_path in os.listdir(path):
            if str(os.path.splitext(each_path)[1]).lower() == ".po": 
                self.process_file(os.path.join(path,each_path))
    
    def process_file(self, file_po):
        basic_section = self.read_config()
        
        bin_path = os.path.join(self.project_folder,"bin")
        log_path = os.path.join(self.project_folder,"log")
        
        command_for_reading = self.read_file(bin_path, file_po)
        dict_result = self.execute_commands(command_for_reading)
    
        if dict_result["result"] and dict_result["message"] == "":
            content_alert = "Archivo registrado exitosamente: %s" % file_po
        else:
            content_alert = "Error al ingresar el archivo: %s" % file_po
            #command_alert = self.send_message(bin_path, basic_section["user"], content_alert)
            #result_alert = self.execute_commands(command_alert)
            #content_alert += result_alert["message"]
    
    def read_config(self):
        config_file = Config()
        basic_section = config_file.get_basic_section()
        
        return basic_section
    
    def read_file(self, bin_path, path_to_file):
        command = "projectsaga"
        main_launcher = os.path.join(bin_path, command)
        
        full_command = '%s "%s"' % (main_launcher, path_to_file)
        
        return full_command
    
    def execute_commands(self, command):
        obj_cmmd = Commands()
        obj_cmmd.execute_command(command)
        return obj_cmmd.get_final_result()
    
    
if __name__ == '__main__':
    clase = ProcessFolder()
    clase.procesar()
    