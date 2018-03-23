# ```miq_apb_tool```

Converts a MIQ Service Template to an Ansible Playbook Bundle format

Pre Requisites

1.       Install the APB python package
2.       Install some ruby gems
      * rest-client

Steps to convert, know the name of your service template.
Normalize the template name to conform to the APB naming rules

1.  Should be all lowercase
1.  Convert underscores (_) to dashes(-)
1.  Cannot start with a digit
  


From some directory


```
apb init <<service_name_converted_to_apb_format>>

cd <<service_name_converted_to_apb_format>>

ruby <<your_git_dir>>/miq_apb_tool/service_template_to_apb.rb -n -r https://<<cfme_server>/api/service_templates/1

```
