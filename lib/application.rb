require 'awesome_print'
require 'vcloud-rest/connection'
require 'yaml'
require 'trollop'
require 'fog'
require_relative 'vapp'

#Usage:
#Options:
     #--vapp-template, -v <s>:   VAPP template to use
         #--vapp-name, -a <s>:   name for the new vapp
  #--vapp-description, -p <s>:   description of the new vapp
       #--org-network, -o <s>:   name of the organization network
                  #--help, -h:   Show this message

cmdline_args = Trollop::options do
  opt :vapp_template, 'VAPP template to use', :type => :string
  opt :vapp_name, 'name for the new vapp', :type => :string
  opt :vapp_description, 'description of the new vapp', :type => :string
  opt :org_network, 'name of the organization network', :type => :string
end

cmdline_args.each do |key, value|
  Trollop::die key, 'is required'  if value.nil?
end

vcloud = Vcloud.new("#{ENV['HOME']}/.credentials.yaml", cmdline_args)
vcloud.debug
vcloud.login

ip_address = vcloud.deploy_vapp(cmdline_args[:vapp_name],
                                cmdline_args[:vapp_description],
                                cmdline_args[:vapp_template],
                                cmdline_args[:org_network])

ap ip_address

