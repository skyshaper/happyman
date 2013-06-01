from fabric.api import *

env.hosts = [
    'shaperia@happyman.skyshaper.org'
]

def deploy():
    local('git push')
    with cd('happyman'):
        run('git pull')
        run('carton install --deployment')
    run('svc -t ~/service/happyman')

def restart():
    run('svc -t ~/service/happyman')
