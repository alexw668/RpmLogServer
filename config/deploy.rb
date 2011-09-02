set :domain, "184.106.193.74"
set :application, "RpmLogServer"
set :repository,  "git@github.com:alexw668/RpmLogServer.git"

set :scm, 'git'
set( :branch, 'master')

# let's use interna IP here for now
role :web, "10.179.83.95"
role :app, "10.179.83.95"

after "deploy", "deploy:cleanup"

set :deploy_to, "/var/www/#{application}"

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

# NOTE: The following is the ideal way to hook up bundler to capistrano, but it won't work for us at the moment
# because bundler isn't in ubuntu-test's default gemset (since it's a shared environment with RPM & RTA)
#require 'bundler/capistrano'

namespace :bundler do
    task :create_symlink, :roles => :app do
        shared_dir = File.join(shared_path, 'bundle')
        release_dir = File.join(current_release, '.bundle')
        sudo("mkdir -p #{shared_dir} && ln -s #{shared_dir} #{release_dir}")
    end

    task :bundle_new_release, :roles => :app do
        bundler.create_symlink
        sudo "cd #{release_path} && bundle install --without development test"
    end
end

after 'deploy:update_code', 'bundler:bundle_new_release'

namespace :deploy do
  task :start do ; end

  task :stop do
    sudo "chmod 766 /var/www/RpmLogServer/current/Gemfile.lock"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    sudo "touch #{File.join(current_path,'tmp','restart.txt')}"
    sudo "chmod 0755 /var/www/RpmLogServer/current/script/rails"
  end

 task :install_gems do
   sudo "cd #{current_path} && #{sudo} bundle install"
 end
end

# Swap in the maintenance page
namespace :app do
  task :disable, :roles => :app do
    on_rollback { sudo "rm #{shared_path}/system/maintenance.html" }

    sudo "[ ! -f #{shared_path}/system/maintenance.html ] && ln -s #{current_path}/public/maintenance.html #{shared_path}/system/maintenance.html"
  end

  task :enable, :roles => :web do
    sudo "rm #{shared_path}/system/maintenance.html"
  end
end

#require 'hoptoad_notifier/capistrano'

