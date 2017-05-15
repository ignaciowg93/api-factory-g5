# config valid only for current version of Capistrano
lock "3.8.1"

set :application, "deployapp"
set :repo_url, "git@github.com:ignaciowg93/api-factory-g5.git"
set :rbenv_path, '/home/deploy/.rbenv'
set :deploy_to, '/home/deploy/deployapp'
set :branch, ENV['BRANCH'] if ENV['BRANCH']

append :linked_files, "config/database.yml", "config/secrets.yml"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "vendor/bundle", "public/system", "public/uploads"