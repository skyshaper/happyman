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
        run('carton install --cached --deployment')
        with cd('python_virtualenv'):
            run('./bin/pip install -r ../cobe_python_requirements.txt')
    execute(restart)

def restart():
    run('svc -t ~/service/happyman')
