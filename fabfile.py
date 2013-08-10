from fabric.api import *

env.hosts = [
    'root@mxeyweb.mxey.net'
]

def init():
    with cd('/srv/happyman/happyman'):
        run('virtualenv python_virtualenv')

def deploy():
    local('git push')
    with cd('/srv/happyman/happyman'):
        run('su happyman -c "git remote update && git reset --hard origin/master"')
        run('su happyman -c "carton install --deployment"')
        with cd('python_virtualenv'):
            run('./bin/pip install -r ../cobe_python_requirements.txt')
    execute(restart)

def restart():
    run('supervisorctl restart happyman')
