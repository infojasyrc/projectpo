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
    project_folder = os.path.dirname(__file__) # Set the path of the project
    patterns=["*.PO", "*.po"] # Set the files to be observed

    def process(self, event):
        '''This function is the main method of this class. It call
        the different functions to process the PO file.
        
        Parameters:
        - event: (Object) Object with the event triggered by the user.
        '''
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
        '''This function call the class that execute all the commands.
        
        Parameters:
        - command: (String) Command with all the parameters.
        
        Return: (dict) A dictionary with the result and the message of the command.
        '''
        
        obj_cmmd = Commands()
        obj_cmmd.execute_command(command)
        return obj_cmmd.get_final_result()
    
    def read_file(self, bin_path, path_to_file):
        '''This function call the command to read the file and save the data in Oracle.
        
        Parameters:
        - bin_path: (String) Path to the bin files.
        - path_to_file: (String) Absolute path of the PO file.
        
        Return: (String) command with all the parameters.
        '''
        command = "projectsaga"
        main_launcher = os.path.join(bin_path, command)
        
        full_command = '%s "%s"' % (main_launcher, path_to_file)
        
        return full_command
    
    def send_message(self, bin_path, user_to_notify, content):
        '''This function call the command to send a message.
        
        Parameters:
        - bin_path: (String) Path to the bin files.
        - user_to_notify: (String) User name to send the message according to the Database.
        - content: (String) Content of the message.
        
        Return: (String) command with all the parameters.
        '''
        command = "enviar_mensaje"
        launcher = os.path.join(bin_path, command)
        full_command = '%s "%s" "%s"' % (launcher, user_to_notify, content)
        
        return full_command
    
    def check_complete_file(self, path_to_file):
        '''This function check is the PO file is completely written.
        
        Parameters:
        - path_to_file: (String) An absolute path of a file.
        
        Return: Boolean.
        '''
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
        '''This function get the basic section of the config file.
        The Config class is used to retrieve the information of the ini file.
        
        Return: (dict) A dictionary with the user and log keys.
        '''
        config_file = Config()
        basic_section = config_file.get_basic_section()
        
        return basic_section
    
    def register_log(self, log_path, log_file, content):
        '''This function save the different process in a log.
        The Log file is at /var/log/saga_po/saga_po.log
        
        Parameters:
        - log_path: (String) An absolute path to save the log file.
        - log_file: (String) A file name for the log file.
        - content: (String) String to be saved in the log file.
        
        Note: In the latest version of the project, the log file is saved at
         /var/log/saga_po/saga_po.log  
        '''
        
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
        '''This function is called when a file is created in the folder observed.
        
        Parameters:
        event: (Object) Object with the information capture with main class.
        '''
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