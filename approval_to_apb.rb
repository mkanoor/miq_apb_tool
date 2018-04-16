class ApprovalToAPB

  def initialize(options)
    @source_dir = File.dirname(__FILE__)
  end

  def convert
    install_role_from_template
    place_role_in_playbook
  end

  def place_role_in_playbook
    filename = "playbooks/provision.yml"
    raise "playbooks/provision.yml not found" unless File.exist?(filename)
    provision_playbook = YAML.load_file(filename)
    if provision_playbook[0]['roles'][2]['role'] == 'manageiq-approval'
      puts "Approval Role found, skipping..."
    else
      provision_playbook[0]['roles'].insert(2, {'role' => 'manageiq-approval', 'any_errors_fatal' => true })
      puts "Overwriting #{filename}"
      File.delete(filename) if File.exist?(filename)
      File.write(filename, provision_playbook.to_yaml)
    end
  end

  def install_role_from_template
    puts "Copying over manageiq-approval role"
    FileUtils.copy_entry "#{@source_dir}/role_templates/manageiq-approval", "./roles/manageiq-approval"
  end
end
