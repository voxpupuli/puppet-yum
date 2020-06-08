Facter.add('yum_package_updates') do
  confine osfamily: 'RedHat'
  setcode do
    yum_updates = []

    if File.executable?('/usr/bin/yum')
      yum_get_result = Facter::Util::Resolution.exec('/usr/bin/yum --assumeyes --quiet --cacheonly list updates')
      unless yum_get_result.nil?
        first_line = true
        yum_get_result.each_line do |line|
          if first_line
            first_line = false
            next
          end
          package, _available_version, _repository = line.split(%r{\s+})
          yum_updates.push(package)
        end
      end
    end

    yum_updates
  end
end

Facter.add('yum_security_updates') do
  confine osfamily: 'RedHat'
  setcode do
    yum_security_updates = Hash.new(Array.new())
    if File.executable?('/usr/bin/yum')
      yum_get_security_result = Facter::Util::Resolution.exec('/usr/bin/yum --quiet updateinfo list security installed') #TODO: --secseverity=Moderate
      unless yum_get_security_result.nil?
        yum_get_security_result.each_line do |line|
          _sec_code, _sec_level, package, trash = line.split(%r{\s+})
          if trash  #some repositories make yum fill with garbage
            next
          end
          _sec_level.chomp!("/Sec.")
          if not yum_security_updates.key?(_sec_level)
            yum_security_updates[_sec_level] = Array.new()
          end
          yum_security_updates[_sec_level].push(package)
        end
      end
    end
    yum_security_updates
  end
end

Facter.add('yum_has_updates') do
  confine osfamily: 'RedHat'
  setcode do
    Facter.value(:yum_package_updates).any?
  end
end

Facter.add('yum_updates') do
  confine osfamily: 'RedHat'
  setcode do
    Facter.value(:yum_package_updates).length
  end
end
