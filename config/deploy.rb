# config valid only for current version of Capistrano
lock "3.8.1"

set :application, "deployapp"
set :repo_url, "git@github.com:ignaciowg93/api-factory-g5.git"
set :rbenv_path, '/home/deploy/.rbenv'
set :deploy_to, '/home/deploy/deployapp'
set :branch, ENV['BRANCH'] if ENV['BRANCH']
# Add this in config/deploy.rb
# and run 'cap production deploy:seed' to seed your database
desc 'Runs rake db:seed'
task :seed do
  on primary fetch(:migration_role) do
    within release_path do
      with rails_env: fetch(:rails_env) do
      	execute :rake, "db:reset"
        execute :rake, "db:seed"
      end
    end
  end
end
append :linked_files, "config/database.yml", "config/secrets.yml"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "vendor/bundle", "public/system", "public/uploads"