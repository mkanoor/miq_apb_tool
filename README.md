# ```miq_apb_tool```

Converts a MIQ Service Template to an Ansible Playbook Bundle format

Install and Setup

Install the APB python package

Clone this repository

```
cd <<your_git_dir>>/miq_apb_tool
```

Run bundle install to install the required gems


Steps to convert a Service Template to APB format.

Know the name of your service template.

Normalize the template name to conform to the APB naming rules

1.  Should be all lowercase
1.  Convert underscores (_) to dashes(-)
1.  Cannot start with a digit
  


From some directory


```
apb init <<service_name_converted_to_apb_format>>

cd <<service_name_converted_to_apb_format>>

**To convert based on the href **
ruby <<your_git_dir>>/miq_apb_tool/service_template_to_apb.rb -n -r https://<<cfme_server>/api/service_templates/1

**To convert based on the service template name**

ruby <<your_git_dir>>/miq_apb_tool/service_template_to_apb.rb -n -t CFME_RHEV

```
