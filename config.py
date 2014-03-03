'''
Created on Mar 3, 2014

@author: Jose Antonio Sal y Rosas Celi
'''

import os
import ConfigParser


class Config(object):
    
    def __init__(self):
        project_folder = os.path.dirname(__file__)
        self.config_file = os.path.join(project_folder,"bin","config.ini")
        
    def get_basic_section(self):
        config = ConfigParser.ConfigParser()
        config.read(self.config_file)
        
        dict_section = {"user": str(config.get('basic','user')), "log":str(config.get('basic','log'))}
        
        return dict_section
    
    def get_path_to_watch(self):
        config = ConfigParser.ConfigParser()
        config.read(self.config_file)
        
        path_to_watch = str(config.get('observer','path'))
        
        return path_to_watch
    