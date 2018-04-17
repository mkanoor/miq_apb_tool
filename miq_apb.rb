##!/usr/env ruby
#

require 'optparse'
require_relative 'service_template_parameters'
require_relative 'service_template'
require_relative 'service_template_to_apb'
require_relative 'approval_to_apb'

options = {:user          => "admin",
           :password      => "smartvm",
           :verify_ssl    => true,
           :quota_check   => false,
           :api_url       => "http://localhost:4000"}

parser = OptionParser.new do|opts|
  opts.banner = "Converts Cloudforms service template to APB.\nUsage: miq_apb.rb [options]"
  opts.on('-u', '--user <<user>>', 'CFME User default: admin') do |user|
    options[:user] = user
  end

  opts.on('-p', '--password <<password>>', 'CFME Password default: smartvm') do |password|
    options[:password] = password
  end

  opts.on('-s', '--url <<url>>', 'CFME Server URL default: http://localhost:4000') do |url|
    options[:url] = url
  end

  opts.on('-t', '--template <<name>>', 'Service Template e.g. CFME_RHEV') do |template|
    options[:template] = template
  end

  opts.on('-r', '--template_href <<url>>', 'Service Template href e.g. https://1.1.1.94/api/service_templates/1') do |template_href|
    options[:template_href] = template_href
  end

  opts.on('-n', '--no_cert_check', 'Disable certificate check') do
    options[:verify_ssl] = false
  end

  opts.on('-q', '--quota_check', 'Enable quota check, disabled by default') do
    options[:quota_check] = true
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end
end

parser.parse!
if options[:template].nil? && options[:template_href].nil?
  puts "template or template_href is required"
  puts parser
  exit 1
end

pwd = Dir.pwd
%w(Dockerfile Makefile apb.yml).each do |f|
  filename = File.join(pwd, f)
  raise "#{filename} not found please ensure you are running this from apb directory" unless File.exist?(filename)
end

%w(playbooks roles).each do |d|
  dirname = File.join(pwd, d)
  raise "#{dirname} not found please ensure you are running this from apb directory" unless Dir.exist?(dirname)
end

ServiceTemplateToAPB.new(options).convert
ApprovalToAPB.new(options).convert
