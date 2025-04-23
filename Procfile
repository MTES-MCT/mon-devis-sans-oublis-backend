web: bin/rails server -p $PORT -e $RAILS_ENV
worker: bundle exec good_job start --queues=critical,default;low
postdeploy: bin/rails db:migrate
