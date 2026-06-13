Puppet::Functions.create_function(:'yum::get_gpg_keys') do
  dispatch :get_gpg_keys do
    param 'String', :key_file
  end

  def get_gpg_keys(key_file)
    keys = []
    if File.exist?(key_file)
      cmd = "/usr/bin/gpg #{key_file}"
      outt = Puppet::Util::Execution.execute(cmd).split("\n")
      # Iterate thru each output line
      outt.each do |line|
        # Only public keys
        if line[0..2] == 'pub'
          the_key = line.split(' ')[1].split('/')[1].downcase
          keys.push(the_key)
        end
      end
    else
      Puppet.warning("Key file '#(key_file)' does not exist")
    end
    keys
  end
end
