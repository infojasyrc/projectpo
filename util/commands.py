'''
Created on Feb 14, 2014

@author: Jose Antonio Sal y Rosas Celi
'''

from subprocess import Popen, CalledProcessError, PIPE, STDOUT
import traceback
import sys


class Commands(object):
    
    def __init__(self):
        self.dict_result = dict()
    
    def execute_command(self, command):         
        try: 
            # Execute command
            p = Popen(command, shell=True, stdin=PIPE, stdout=PIPE, stderr=STDOUT, close_fds=True)
            # Get output
            rs_cmd = p.stdout.read()
            
            self.dict_result = {"result":True, "message":rs_cmd}
            
        except CalledProcessError:
            err = traceback.format_exception(sys.exc_info()[0],sys.exc_info()[1],sys.exc_info()[2])
            
            self.dict_result = {"result":False, "message":err}
    
    
    def get_final_result(self):
        return self.dict_result
    
    def get_result(self):
        return self.dic_result["result"]
    
    def get_message(self):
        return self.dic_result["message"]
    
    def print_message(self):
        print self.dict_result["message"]


if __name__ == '__main__':
    command = "ls -al"
    obj_command = Commands()
    obj_command.execute_command(command)
    obj_command.print_result()
    