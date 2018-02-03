#coding: utf-8
import sys,public,json,os;
class ss_main:
    __config = '/www/server/panel/plugin/ss/config.json'
        
    #Read a string in a file
    def __read_file(self,filename):
        if not os.path.exists(filename): return False;
        f = open(filename,'r')
        fbody = f.read()
        f.close()
        return fbody
    
    #Write a string to a file
    def __write_file(self,filename,fbody):
        f = open(filename,'w+')
        f.write(fbody)
        f.close()
    
    #Write the configuration file
    def __set_config(self,sconfig):
        self.__write_file(self.__config, json.dumps(sconfig))
        self.service_admin('restart')
        return True;
    
    #Read the configuration file
    def get_config(self,input):
        fbody = self.__read_file(self.__config)
        return json.loads(fbody)
    
    #List all user port information 
    def get_users(self,input):
        sconfig = self.get_config(None);
        users = []
        for port in sconfig['port_password']:
            u_tmp = {}
            u_tmp['port'] = port
            u_tmp['password'] = sconfig['port_password'][port]
            users.append(u_tmp)
        return users
    
    #Get configuration option
    def get_options(self,input):
        sconfig = self.get_config(None)
        del(sconfig['port_password'])
        return sconfig
    
    #Modify configuration options
    def set_options(self,input):
        sconfig = self.get_config(None)
        sconfig['server'] = input.server
        sconfig['local_address'] = input.local_address
        sconfig['local_port'] = input.local_port
        sconfig['timeout'] = input.timeout
        sconfig['method'] = input.method
        self.__set_config(sconfig)
        return True
    
    #Check the presence of the user port
    def user_exists(self,port):
        users = self.get_users(None)
        for user in users:
            if user['port'] == port: return True
        return False
    
    #Create a new user port and Modifying the access password of the user port
    def create_user(self,input):
        sconfig = self.get_config(None);
        sconfig['port_password'][input.port] = input.password
        self.__set_config(sconfig)
        self.__accept_port(input.port)
        return True
    
    #Delete user ports
    def remove_user(self,input):
        if not self.user_exists(input.port): return False
        sconfig = self.get_config(None)
        del(sconfig['port_password'][input.port])
        self.__set_config(sconfig)
        self.__remove_port(input.port)
        return True
    
    #Service control
    def service_admin(self,input):
        status = input
        if type(input) != str: status = input.status
        os.system('/etc/init.d/ss ' + status)
        return True
    
    #Get service status
    def get_status(self,input):
        result = public.ExecShell('ps aux|grep ssserver|grep -v grep')
        if len(result[0]) > 10: return True
        return False
    
    #Accept new ports from the firewall
    def __accept_port(self,port):
        os.system('bash /www/server/panel/plugin/ss/install.sh port ' + port)
        return True
    
    #Delete the port from the firewall
    def __remove_port(self,port):
        os.system('bash /www/server/panel/plugin/ss/install.sh rmport ' + port)
        return True
    
        
        
        