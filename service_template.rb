require 'rest-client'
require 'json'
require 'yaml'

class ServiceTemplate
  attr_reader :api_url
  attr_reader :cfme_console_url

  def initialize(options = {})
    @url           = options[:url]
    @user          = options[:user]
    @password      = options[:password]
    @template      = options[:template]
    @verify_ssl    = options[:verify_ssl]
    @template_href = options[:template_href]
    @api_url       = build_api_url(@template_href || @url)
    @cfme_console_url = build_console_url(@template_href || @url)
  end

  def get_dialog(action)
    provisioned_storage
    dialog_id = object['config_info']['dialog_id'] || 
      @object['config_info'][action]['dialog_id']
    unless dialog_id
      puts "No Service Dialog found for Service Template #{@template || @template_href}"
      return {}
    end
  
    query = "/service_dialogs/#{dialog_id}"
    rest_return = RestClient::Request.execute(:method => :get,
                                              :url    => @api_url + query,
                                              :user   => @user,
                                              :password => @password,
                                              :headers  => {:accept => :json},
                                              :verify_ssl => @verify_ssl)
    return JSON.parse(rest_return)
  end

  def object
    @object ||= @template_href ? template_by_href : template_by_name
  end

  def provisioned_storage
    src = object['config_info']['src_vm_id']
    unless src
      puts "No VM Template found for service #{@template || @template_href}"
      return nil
    end
    query = "/templates/#{src.first}?attributes=provisioned_storage"
    rest_return = RestClient::Request.execute(:method => :get,
                                              :url    => @api_url + query,
                                              :user   => @user,
                                              :password => @password,
                                              :headers  => {:accept => :json},
                                              :verify_ssl => @verify_ssl)
    JSON.parse(rest_return)['provisioned_storage']
  end

  private

  def template_by_name
    puts "Fetching Service Template #{@template}"
    query = "/service_templates?filter[]=name=#{@template}&expand=resources&attributes=config_info,picture.image_href"
    rest_return = RestClient::Request.execute(:method => :get,
                                              :url    => @api_url + query,
                                              :user   => @user,
                                              :password => @password,
                                              :headers  => {:accept => :json},
                                              :verify_ssl => @verify_ssl)
    JSON.parse(rest_return)['resources'].first.tap do |svc_template|
      raise "Service Template #{@template} not found" unless svc_template
    end
  end

  def template_by_href
    puts "Fetching Service Template #{@template_href}"
    # query = "&attributes=config_info,picture.image_href"
    rest_return = RestClient::Request.execute(:method => :get,
                                              :url    => @template_href,
                                              :user   => @user,
                                              :password => @password,
                                              :headers  => {:accept => :json},
                                              :verify_ssl => @verify_ssl)
    JSON.parse(rest_return) do |svc_template|
      raise "Service Template #{@template_href} not found" unless svc_template
    end
  end

  def build_api_url(url)
    raise "url not specified" unless url
    parts = URI.parse(url)
    parts.path = "/api"
    parts.to_s
  end

  def build_console_url(url)
    raise "url not specified" unless url
    parts = URI.parse(url)
    parts.path = ""
    parts.to_s
  end
end
