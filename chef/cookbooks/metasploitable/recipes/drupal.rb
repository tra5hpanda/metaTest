#
# Cookbook:: metasploitable
# Recipe:: drupal
#
# Copyright:: 2017, Rapid7, All Rights Reserved.

include_recipe 'metasploitable::apache'
include_recipe 'metasploitable::mysql'
include_recipe 'metasploitable::php_545'

package 'unzip'

drupal_tar    = "drupal-#{node[:drupal][:version]}.tar.gz"
coder_tar     = "coder-7.x-2.5.tar.gz"
files_path    = File.join(Chef::Config[:file_cache_path], 'cookbooks', 'metasploitable', 'files', 'drupal')

remote_file "#{Chef::Config[:file_cache_path]}/#{drupal_tar}" do
  source "#{node[:drupal][:download_url]}/#{drupal_tar}"
  mode '0644'
end

remote_file "#{Chef::Config[:file_cache_path]}/#{coder_tar}" do
  source "#{node[:drupal][:download_url]}/#{coder_tar}"
  mode '0644'
end

directory node[:drupal][:install_dir] do
  owner 'www-data'
  group 'www-data'
  recursive true
  mode '0755'
end

log "debug logging" do
  message "#{Dir["#{node[:drupal][:install_dir]}/*"]}"
  level :info
end

execute 'untar drupal' do
  cwd node[:drupal][:install_dir]
  command "tar xvzf #{Chef::Config[:file_cache_path]}/#{drupal_tar} --strip-components 1"

  only_if { Dir["#{node[:drupal][:install_dir]}/*"].empty? }
end

execute 'untar coder module' do
  cwd File.join(node[:drupal][:all_site_dir], 'modules')
  command "tar xvzf #{Chef::Config[:file_cache_path]}/#{coder_tar}"
  not_if { ::File.directory?(File.join(node[:drupal][:all_site_dir], 'modules', 'coder')) }
end

execute "set permissions" do
  command "chown -R www-data:www-data #{node[:drupal][:install_dir]}"
end

bash "create drupal database and inject data" do
  code <<-EOH
    mysql -h 127.0.0.1 --user="root" --password="gmips123" --execute="CREATE DATABASE drupal;"
    mysql -h 127.0.0.1 --user="root" --password="gmips123" --execute="GRANT SELECT, INSERT, DELETE, CREATE, DROP, INDEX, ALTER ON drupal.* TO 'root'@'localhost' IDENTIFIED BY 'gmips123';"
	mysql -h 127.0.0.1 --user="Vanessa.Cohen" --password="Y7lNl" --execute="GRANT SELECT, INSERT, DELETE, CREATE, DROP, INDEX, ALTER ON drupal.* TO 'Vanessa.Coehn'@'localhost' IDENTIFIED BY 'Y7lNl';"
	mysql -h 127.0.0.1 --user="root" --password="gmips123" drupal < #{File.join(files_path, 'drupal.sql')}
  EOH
  not_if "mysql -h 127.0.0.1 --user=\"root\" --password=\"gmips123\" --execute=\"SHOW DATABASES LIKE 'drupal'\" | grep -c drupal"
end
