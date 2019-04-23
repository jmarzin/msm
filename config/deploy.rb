##
# le fichier de paramétrage de nginx est dans /etc/nginx (modifiable sous root)
# le fichier de logs de nginx est dans /var/logs/nginx (accessible sous root)
# pour migrer la base faire       RAILS_ENV=production rails db:migrate
# pour compiler les assets faire  RAILS_ENV=production rails assets:precompile
# pour lancer le serveur faire    bundle exec puma -e production -d --pidfile RUNNINGPID
# pour relancer le serveur faire  kill -s SIGUSR2 `cat RUNNINGPID`
# pour arrêter le serveur faire   kill -s SIGTERM `cat RUNNINGPID`
set :format, :pretty
set :repo_url, 'https://github.com/jmarzin/msm.git'

set :deploy_to, '/home/deploy/msm'

set :linked_files, %w{config/master.key}
set :linked_files, %w{config/database.yml public/agenda.txt}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/assets public/system public/images public/gpx public/materiels}

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, 'deploy:restart'
  after :finishing, 'deploy:cleanup'
end