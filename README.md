## Pasos por si falla la base de datos

* rake db:reset DISABLE_DATABASE_ENVIRONMENT_CHECK=1
* rake db:environment:set RAILS_ENV=production
* rake db:schema:load RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1
* rake db:migrate
* rake db:seed
