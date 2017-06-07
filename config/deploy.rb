# config valid only for current version of Capistrano

# NO estoy seguro aun, hagamoslo correr y luego al deploy
# require 'whenever/capistrano'


lock "3.8.1"

set :application, "deployapp"
set :repo_url, "git@github.com:ignaciowg93/api-factory-g5.git"
set :rbenv_path, '/home/deploy/.rbenv'
set :deploy_to, '/home/deploy/deployapp'
set :branch, ENV['BRANCH'] if ENV['BRANCH']

# NO estoy seguro aun, hagamoslo correr y luego al deploy
# set :whenever_environment, defer { stage }
# set :whenever_command, 'bundle exec whenever'

# Add this in config/deploy.rb
# and run 'cap production deploy seed' to seed your database
desc "deploy app for the first time (expects pre-created but empty DB)"
task :cold do
  before 'deploy:migrate', 'deploy:initdb'
  invoke 'deploy'
end

desc "initialize a brand-new database (db:schema:load, db:seed)"
task :initdb do
  on primary :web do |host|
    within release_path do
      if test(:psql, 'portal_production -c "SELECT table_name FROM information_schema.tables WHERE table_schema=\'public\' AND table_type=\'BASE TABLE\';"|grep schema_migrations')
        puts '*** THE PRODUCTION DATABASE IS ALREADY INITIALIZED, YOU IDIOT! ***'
      else
        execute :rake, 'db:schema:load'
        execute :rake, 'db:seed'
      end
    end
  end
end
desc 'Runs rake db:seed'
task :seed do
  on primary fetch(:migration_role) do
    within release_path do
      with rails_env: fetch(:rails_env) do
        #execute :rake, "db:reset DISABLE_DATABASE_ENVIRONMENT_CHECK=1"
        #execute :rake, "db:schema:load"
        execute :rake, 'db:seed'
        #execute :rake, "db:setup"
      end
    end
  end
end

append :linked_files, "config/database.yml", "config/secrets.yml"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "vendor/bundle", "public/system", "public/uploads"
