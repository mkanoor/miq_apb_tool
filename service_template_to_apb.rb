##!/usr/env ruby
#

require 'optparse'
require 'yaml'
require 'fileutils'
require_relative 'service_template_parameters'
require_relative 'service_template'

class ServiceTemplateToAPB
  CFME_REQUESTER = {'title' => 'CFME Requester', 'name' => 'cfme_user',
                    'type' => 'string', 'required' => true,
                    'display_group' => 'CloudForms Credentials' }
  CFME_PASSWORD  = {'title' => 'CFME Password', 'name' => 'cfme_password',
                    'type' => 'string', 'display_type' => 'password', 'required' => true,
                    'display_group' => 'CloudForms Credentials' }

  PROVISION_TASK_NAME = "CloudForms Provisioning Task"
  DEFAULT_PLAN_NAME   = "default"

  def initialize(options = {})
    @svc_template  = ServiceTemplate.new(options)
    @apb_yml_file  = 'apb.yml'
    @max_retries   = 200
    @retry_interval = 60
    @apb_dir        = "."
    @source_dir     = File.dirname(__FILE__)
    @quota_check    = options[:quota_check]
  end

  def apb_normalized_name(name)
    @apb_name ||= "#{name.downcase.gsub(/[()_,. ]/, '-')}-apb"
  end

  def plans
    return [] unless Dir.exist?("#{@apb_dir}/plans")
    @plan_list ||= Dir.entries("#{@apb_dir}/plans").select { |f| File.extname(f) == ".yml" }.map { |f| f.split('.').first }
  end

  def create_apb_yml(parameters)
    puts "Creating apb yaml file #{@apb_yml_file} for service template #{@svc_template.object['name']}"
    metadata = { 'displayName' => "#{@svc_template.object['name']} (APB)" }
    metadata['imageUrl'] = @svc_template.object['picture']['image_href'] if @svc_template.object['picture']

    @svc_template.object['description'] = 'No description provided' if @svc_template.object['description'].empty?


    apb = {'version' => 1.0,
           'name'    => apb_normalized_name(@svc_template.object['name']),
           'description' => @svc_template.object['description'] || 'No description provided',
       'bindable'    => false,
       'async'      => 'optional',
       'metadata'   => metadata,
       'plans'      => create_plans(parameters)
    }

    File.write(@apb_yml_file, apb.to_yaml)
  end

  def create_plans(parameters)
    return [default_plan(parameters)] if plans.empty?
    plans.each.collect do | plan|
      plan_attrs = YAML.load_file("#{@apb_dir}/plans/#{plan}.yml")
      plan_metadata = { 'displayName'     => plan_attrs['plan_display_name'] || plan,
                        'longDescription' => plan_attrs['plan_long_description'] || plan_attrs['plan_description'],
                        'cost'            => plan_attrs['plan_cost']}
      {'name'         => plan,
       'description' => plan_attrs['plan_description'],
       'free'        => plan_attrs['plan_free'] || false,
       'metadata'    => plan_metadata,
       'parameters'  => plan_parameters(parameters, plan_attrs.keys)
      }
    end
  end

  def default_plan(parameters)
    metadata = { 'displayName' => 'Default',
                 'longDescription' => "This plan deploys an instance of #{@svc_template.object['name']}",
                 'cost'            => '$0.0'
               }

    {'name'        => DEFAULT_PLAN_NAME,
     'description' => "Default deployment plan for #{@svc_template.object['name']}-apb",
     'free'        => true,
     'metadata'    => metadata,
     'parameters'  => parameters
    }
  end

  def plan_parameters(parameters, plan_attr_names)
    parameters.reject { |param| plan_attr_names.include?(param['name']) }
  end

  def create_vars_yml(parameters, apb_action, enum_mappings)
    puts "create vars directory"
    vars_dir = File.join(@apb_dir, "roles/#{apb_action}-#{@apb_name}/vars")
    Dir.mkdir(vars_dir) unless Dir.exist?(vars_dir)
    filename = File.join(vars_dir, "main.yml")
    puts "Creating vars yaml file #{filename} for service template #{@svc_template.object['name']}"

    manageiq_vars = {'api_url'               => @svc_template.api_url,
                     'max_retries'           => @max_retries,
                     'quota_check'           => @quota_check,
                     'retry_interval'        => @retry_interval}
    if apb_action == 'provision'
      sc_href = @svc_template.api_url+"/service_catalogs/" +  @svc_template.object['service_template_catalog_id'] + "/service_templates"
      manageiq_vars['service_catalog_href'] = sc_href
      manageiq_vars['href']                 = @svc_template.object['href']
      manageiq_vars['enum_map']             = enum_mappings
    end
    vars = { 'manageiq' => manageiq_vars}
    File.write(filename, vars.to_yaml)
    plans.empty? ? copy_default_plan_vars(vars_dir) : copy_plan_vars(vars_dir)
  end

  def copy_plan_vars(vars_dir)
    plans.each { |plan| FileUtils.cp("#{@apb_dir}/plans/#{plan}.yml", File.join(vars_dir, "#{plan}.yml")) }
  end

  def copy_default_plan_vars(vars_dir)
    File.write("#{vars_dir}/default.yml", {:plan_name => DEFAULT_PLAN_NAME}.to_yaml)
  end

  # What happens to optional parameters
  def create_provision_yml(parameters)
    template_file = File.join(@source_dir, "/templates/provision.yml")
    raise "templates/provision.yml not found in #{@source_dir}" unless File.exist?(template_file)
    ansible_tasks = YAML.load_file(template_file)
    ansible_tasks.detect { |task| task['name'] == PROVISION_TASK_NAME }.tap do |prov_task|
      if prov_task
        parameters.each do |param|
          prov_task['uri']['body']['resource'][param['name']] = if param['type'] == 'enum'
                                                                  set_enum_param(param['name'])
                                                                else
                                                                  "{{ #{param['name']} }}"
                                                                end
        end
      end
    end
    filename = File.join(@apb_dir, "roles/provision-#{@apb_name}/tasks/main.yml")
    puts "Overwriting #{filename}"
    File.delete(filename) if File.exist?(filename)
    File.write(filename, ansible_tasks.to_yaml)
  end

  def create_retirement_yml
    template_file = File.join(@source_dir, "/templates/deprovision.yml")
    raise "templates/deprovision.yml not found in #{@source_dir}" unless File.exist?(template_file)
    # Make sure that the template is valid and parseable
    ansible_tasks = YAML.load_file(template_file)
    filename = File.join(@apb_dir, "roles/deprovision-#{@apb_name}/tasks/main.yml")
    puts "Overwriting #{filename}"
    File.delete(filename) if File.exist?(filename)
    File.write(filename, ansible_tasks.to_yaml)
  end

  def set_enum_param(name)
    "{{ [#{name}]|map('extract',manageiq.enum_map.#{name})|list|first }}"
  end

  def convert
    ['provision', 'retirement'].each do |action|
      action_parameters = ServiceTemplateParameters.new
      def_params = []
      def_params << CFME_REQUESTER
      def_params << CFME_PASSWORD
      result = @svc_template.get_dialog(action)
      action_parameters.process_tabs(result['content'][0]['dialog_tabs']) if result['content']

      case action
      when "provision"
        create_apb_yml(def_params + action_parameters.parameters)
        create_provision_yml(action_parameters.parameters)
        create_vars_yml(def_params + action_parameters.parameters, 'provision', action_parameters.enum_mappings)
      when 'retirement'
        create_retirement_yml
        create_vars_yml({}, 'deprovision', action_parameters.enum_mappings)
      else
        raise "Invalid action #{action}"
      end
    end
  rescue => err
    puts "#{err}"
    puts "#{err.backtrace}"
    exit!
  end
end
