# miq_apb_tool
Converts a MIQ Service Template to an Ansible Playbook Bundle format
Pre-reqs
      Install the APB python packages
      Install some ruby gems
      * rest-client

Steps to convert, know the name of your service template, lowercase convert all _ to -
From some directory
```
apb init <<service_name_converted_to_apb_format>>
cd <<service_name_converted_to_apb_format>>
ruby <<your_git_dir>>/miq_apb_tool/service_template_to_apb.rb -n -r https://<<cfme_server>/api/service_templates/1
```
