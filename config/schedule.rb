if "#{ENV['RACK_ENV']}" == "production"
    job_type :sidekiq,  "cd :path && EB_SCRIPT_DIR=$(/opt/elasticbeanstalk/bin/get-config container -k script_dir) &&  EB_SUPPORT_DIR=$(/opt/elasticbeanstalk/bin/get-config container -k support_dir) && . $EB_SUPPORT_DIR/envvars && . $EB_SCRIPT_DIR/use-app-ruby.sh && RAILS_ENV=$RACK_ENV bundle exec sidekiq-client :task :output"
else
    job_type :sidekiq,  "cd :path && source ~/.bashrc && bundle install && RAILS_ENV=$RACK_ENV bundle exec sidekiq-client :task :output"
end

#every 30.minute do
#    sidekiq "push NotificationWorker"
#end
