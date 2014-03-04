'''
Created on Mar 3, 2014

@author: Jose Antonio Sal y Rosas Celi
'''

import os
import ConfigParser


class Config(object):
    ''' This class read the basic and observer section of the INI (Configuration) File.'''
    
    def __init__(self):
        ''' The constructor set the current path of the project and the path of the INI file.
        By default the INI file is at: PROJECT_PATH\BIN\config.ini
        '''
        project_folder = os.path.dirname(__file__)
        self.config_file = os.path.join(project_folder,"bin","config.ini")
        
    def get_basic_section(self):
        ''' This function get the basic section of the INI file.
        Return: A dictionary with the following keys:
                - user: User name to send the error message.
                - log: Filename of the log.
        '''
        config = ConfigParser.ConfigParser()
        config.read(self.config_file)
        
        dict_section = {"user": str(config.get('basic','user')), "log":str(config.get('basic','log'))}
        
        return dict_section
    
    def get_path_to_watch(self):
        ''' This function get the observer section of the INI (configuration) file.
        Return: A string with the path to watch all the files in it.        
        '''
        config = ConfigParser.ConfigParser()
        config.read(self.config_file)
        
        path_to_watch = str(config.get('observer','path'))
        
        return path_to_watch
    