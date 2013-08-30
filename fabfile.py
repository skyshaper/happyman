from fabric.api import *

env.hosts = [
    'shaperia@lynx.uberspace.de'
]

env.target_directory = './happyman'

def init():
    run('git clone -q https://github.com/skyshaper/happyman.git ' + env.target_directory)
    with cd(env.target_directory):
        run('virtualenv ./python/virtualenv')

def deploy():
    local('git push')
    with cd(env.target_directory):
        run('git remote update && git reset --hard origin/master')
        run('./vendor/bin/carton install --cached --deployment --without develop,test')
        run('./python/virtualenv/bin/pip install --no-index --find-links=python/vendor/cache/ -r python/requirements_lock.txt')
    execute(restart)

def restart():
    run('svc -t ~/service/happyman')
