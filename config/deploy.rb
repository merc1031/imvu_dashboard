require 'rvm/capistrano'
require 'bundler/capistrano'

ssh_options[:forward_agent] = true

set :thin_port, 5000
set :domain, 'tv-dashboard.corp.imvu.com'
set :application, 'imvu_dashboard'
set :repository,  'git@github.com:mattcl/imvu_dashboard.git'
set :scm, :git


set :user, 'deploy'
set :use_sudo, false

role :web, domain
role :app, domain
role :db,  domain, :primary => true

set :deploy_to, "/home/#{user}/#{application}"
set :deploy_via, :remote_cache

namespace :deploy do
    desc "Start dashing"
    task :start do
        run "cd #{current_path} && bundle exec thin -d -R config.ru -e production -p #{thin_port} start"
    end

    task :stop do
        run "cd #{current_path} && bundle exec thin stop"
    end

    task :restart do
        run "cd #{current_path} && bundle exec thin restart"
    end

    task :finalize_update, :except => { :no_release => true } do
        run "chmod -R g+w #{latest_release}" if fetch(:group_writeable, true)

        run <<-CMD
            rm -rf #{latest_release}/log &&
            mkdir -p #{latest_release}/public &&
            mkdir -p #{latest_release}/tmp &&
            ln -s #{shared_path}/log #{latest_release}/log
        CMD

        if fetch(:normalize_asset_timestamps, true)
        end
    end
end

