# ```miq_apb_tool```

Converts a MIQ Service Template to an Ansible Playbook Bundle format

Install and Setup

Install the Ansible Playbook Bundle (apb) python package

1.	pip install apb
2.	apb --help
  

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
Since this tool is used in conjunction the apb tool the recommended steps are

1. apb init <<service_name_converted_to_apb_format>>

2. cd <<service_name_converted_to_apb_format>>

**To convert service template based on the href **
3. ruby <<your_git_dir>>/miq_apb_tool/service_template_to_apb.rb -n -r https://<<cfme_server>/api/service_templates/1

**To convert based on the service template name**

ruby <<your_git_dir>>/miq_apb_tool/service_template_to_apb.rb -n -t CFME_RHEV


** Now we are back to using the apb tool

4. apb prepare
      

5. apb push

```