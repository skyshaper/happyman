from fabric.api import *

env.hosts = [
    'shaperia@lynx.uberspace.de'
]

env.target_directory = './happyman'

def init():
    run('git clone -q https://github.com/skyshaper/happyman.git ' + env.target_directory)
    with cd(env.target_directory):
        run('virtualenv python_virtualenv')

def deploy():
    local('git push')
    with cd(env.target_directory):
        run('git remote update && git reset --hard origin/master')
        run('./vendor/bin/carton install --cached --deployment')
        run('./python_virtualenv/bin/pip install --no-index --find-links=vendor/python_cache/ -r cobe_python_requirements_lock.txt')
    execute(restart)

def restart():
    run('svc -t ~/service/happyman')
