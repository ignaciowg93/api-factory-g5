## Pasos por si falla la base de datos
### (correr en la base de datos)

* bundle exec rake db:reset RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1
* bundle exec rake db:environment:set RAILS_ENV=production
* bundle exec rake db:schema:load RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1
* bundle exec rake db:migrate RAILS_ENV=production
* bundle exec rake db:seed RAILS_ENV=production
