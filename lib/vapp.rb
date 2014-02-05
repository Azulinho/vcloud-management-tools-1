class Vcloud
  def initialize(credentials_file, cmdline_args)
    @credentials_file = credentials_file
    @cmdline_args = cmdline_args
  end

  def cmdline_args
    @cmdline_args
  end

  def credentials_file
    @credentials_file
  end

  def credentials
    # load up the credentials from ~/.vcloud-credentials.yaml
    #credentials = YAML.load_file("#{ENV['HOME']}/.credentials.yaml")
    YAML.load_file(credentials_file)
    # Example yaml contents for the credentials ~/.credentials.yaml file
    # ---
    #vcloud:
    #  host: 'https://api.vcd.portal.cloud.com'
    #  user: '999.88.AA00d2'
    #  password: 'whateveryoufancy,really'
    #  org_name: '99-88-0-ffffff'
    #  vdc_name: 'ffffffff-ffff-ffff-ffff-ffffffffffff'
    #  catalog_name: 'VappCatalog'
    #  api_version: '6.1'
    #dnsimple:
    #  username: adskjfdsaf@asdf.pt
    #  password: ksadfkjsadfkj
    #
  end

  def vcloud_credentials
    credentials['vcloud']
  end

  def dnsimple_credentials
    credentials['dnsimple']
  end

  def slowdown_vcloud
    sleep 5
  end

  def login
    #login and get your session token
    @vcloud = VCloudClient::Connection.new(vcloud_credentials['host'],
                                          vcloud_credentials['user'],
                                          vcloud_credentials['password'],
                                          vcloud_credentials['org_name'],
                                          vcloud_credentials['api_version'])

    @vcloud.login
  end

  def orgs
    # retrieve the list of vcloud organizations this user has access
    slowdown_vcloud
    @vcloud.get_organizations
  end

  def org
    # retrieve all objects within this specific organization
    slowdown_vcloud
    @vcloud.get_organization(orgs[vcloud_credentials['org_name']])
  end

  def networks
    # retrieve the list of networks within the organization
    org[:networks]
  end

  def vdcs
    # retrieve the list of vdcs within the organization
    org[:vdcs]
  end

  def vdc
      vcloud_credentials['vdc_name']
  end

  def catalog_uuid
    # retrieve catalog uuid and then the list of all vapps inside that catalog
    @vcloud.get_catalog_id_by_name(org, vcloud_credentials['catalog_name'])
  end

  def vapp_template_uuid
    # get the catalog item uuid for my VAPP template
    # this is not pretty!
    # the reason is that the VAPP template uuid required to deploy from template
    # is not the the uuid for that catalog item.
    # the item object in the catalog contains a set of children items inside it
    # and we require the first :id contained in it.
    #
    @vcloud.get_catalog_item_by_name(
      catalog_uuid,
      cmdline_args[:vapp_template],
      )[:items][0][:id]
  end

  def network_uuid
    networks[cmdline_args[:org_network]]
  end

  def network
    @vcloud.get_network(network_uuid)
  end

  def org_network
    cmdline_args[:org_network]
  end

  def get_vapp_template_uuid(vapp_template)
    @vcloud.get_catalog_item_by_name(catalog_uuid,
      vapp_template,
      )[:items][0][:id]
  end

  def deploy_vapp(vapp_name, vapp_description, vapp_template, org_network)
    vapp = @vcloud.create_vapp_from_template(
      vdc,
      vapp_name,
      vapp_description,
      get_vapp_template_uuid(vapp_template),
      false)

    # wait until the VAPP is deployed
    @vcloud.wait_task_completion(vapp[:task_id])

    slowdown_vcloud

    #reconfigure the networks for the vapp
    @vcloud.add_org_network_to_vapp(vapp[:vapp_id], network, config)

    slowdown_vcloud

    # poweron
    poweron_taskid = @vcloud.poweron_vapp(vapp[:vapp_id])

    slowdown_vcloud
    # wait for task completion
    @vcloud.wait_task_completion(poweron_taskid)

    # find out the ip address of my new vapp
    # this can take a while, so lets loop around it for a bit

    slowdown_vcloud

    until ip_address = @vcloud.get_vapp(vapp[:vapp_id])[:ip] do
      slowdown_vcloud
    end

    ip_address
  end

  def config
    {
      :name => org_network,
      :fence_mode => "bridged",
      :parent_network =>  {
        :id => networks[org_network] },
      :ip_allocation_mode => "DHCP"
    }
  end

  def debug
    ENV['VCLOUD_REST_DEBUG_LEVEL'] = "DEBUG"
  end
end

class DNS
  def initialize(credentials_file)
    @credentials_file = credentials_file
  end

  def dnsimple_credentials
    YAML.load_file(@credentials_file)['dnsimple']
  end

  def login
    # register new vapp into DNS
    @dnsimple = Fog::DNS.new({
      :provider     => 'DNSimple',
      :dnsimple_email => dnsimple_credentials['username'],
      :dnsimple_password => dnsimple_credentials['password']
    })
    @dnsimple
  end

  def add_record(vapp_name, domain, subdomain, ip_address)
    zone = @dnsimple.zones.get(domain)

    record = zone.records.create(
    :value => ip_address,
    :name => vapp_name + '.' + subdomain,
    :type => 'A'
    )
    ap record
  end
end

