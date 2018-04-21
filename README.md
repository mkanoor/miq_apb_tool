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



Since this tool is used in conjunction the apb tool the recommended steps are

0. Make sure you have the OpenShift environment setup which will host the service template in its catalog.

1. ```apb init <<service_template_name_converted_to_apb_format>>```

2. ``` cd <<service_template_name_converted_to_apb_format>>```

3. Optionally create plan files
	In the apb directory create a directory called plans
	Each plan can be represented as a YAML file and contains constants for a plan. These constants will be ignored from the dialog and not displayed to the end user.
	The plan can contain quota attributes, plan attributes and other attributes needed for the service
	
	```
	option_0_cores_per_socket
	option_0_number_of_cores
	option_0_number_of_vms
	option_0_vm_memory
	provisioned_storage
	plan_description
	plan_cost
	plan_free
	plan_long_description
	plan_display_name
	```
5.

**To convert service template based on the href**

```ruby <<your_git_dir>>/miq_apb_tool/service_template_to_apb.rb -n -r https://<<cfme_server>/api/service_templates/1```

**To convert based on the service template name**

```ruby <<your_git_dir>>/miq_apb_tool/service_template_to_apb.rb -n -t CFME_RHEV```



** Now we are back to using the apb tool **

6. apb prepare
      
7. apb push

