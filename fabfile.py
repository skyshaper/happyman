from fabric.api import *

env.hosts = [
    'root@mxeyweb.mxey.net'
]

def deploy():
    local('git push')
    with cd('/srv/happyman/happyman'):
        run('su happyman -c "git remote update && git reset --hard origin/master"')
        run('su happyman -c "carton install --deployment"')
    execute(restart)

def restart():
    run('supervisorctl restart happyman')
