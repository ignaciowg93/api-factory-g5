# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
env :PATH, ENV['PATH']


/every 30.minutes do
   runner "Ftp.ordenes_compra", :enviroment => "production", :output => 'log/check_status_update.log'
end

# every 113.minutes do
every 6.hours do
   runner "Warehouse.revisar_maiz", :enviroment => "production", :output => 'log/maiz.log'
end

# every 201.minutes do
every 6.hours do
   runner "Warehouse.revisar_yogur", :enviroment => "production", :output => 'log/yogur.log'
end

# every 95.minutes do
every 6.hours do
   runner "Warehouse.revisar_leche", :enviroment => "production", :output => 'log/leche.log'
end

# every 180.minutes do
every 6.hours do
   runner "Warehouse.revisar_carne", :enviroment => "production", :output => 'log/carne.log'
end

# every 194.minutes do
every 6.hours do
   runner "Warehouse.revisar_margarina", :enviroment => "production", :output => 'log/margarina.log'
end

# every 95.minutes do
every 6.hours do
   runner "Warehouse.revisar_avena", :enviroment => "production", :output => 'log/avena.log'
end

# every 80.minutes do
every 6.hours do
   runner "Warehouse.cereal_arroz", :enviroment => "production", :output => 'log/arroz.log'
end

# every 120.minutes do
every 6.hours do
   runner "Warehouse.mantequilla", :enviroment => "production", :output => 'log/mantequilla.log'
end

# every 177.minutes do
every 6.hours do
   runner "Warehouse.revisar_azucar", :enviroment => "production", :output => 'log/azucar.log'
end

# every 100.minutes do
every 6.hours do
   runner "Warehouse.harina_integral", :enviroment => "production", :output => 'log/harina_integral.log'
end

# every 101.minutes do
every 6.hours do
   runner "Warehouse.hamburguesas_pollo", :enviroment => "production", :output => 'log/hamburguesas_pollo.log'
end/
