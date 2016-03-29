# coding: utf-8
from fabric.api import env
from fabric_swat.utils import Mod, ModX, Server, ServerX
from fabric_swat import make, server, dist  # noqa


env.always_use_pty = False
env.use_ssh_config = True

env.roledefs = {
    'make': ['modder@sandbox'],
    'server': ['swat@sandbox']
}

env.hosts = []


class Settings:
    name = 'Julia'
    version = '2.4.0-dev'
    git = 'git@git:games/swat'
    packages = [
        ('Utils', 'git@git:swat/swat-utils'),
        ('Julia', 'git@git:swat/swat-julia'),
    ]
    mods = [
        Mod('swat4', '/home/modder/swat4', revision='origin/modding/swat4'),
        ModX('swat4tss', '/home/modder/swat4tss', revision='origin/modding/swat4tss',
             content_dir='ContentExpansion'),
    ]
    servers = [
        Server('swat4', '/home/swat/swat4',
               revision='origin/server/team',
               settings={
                   'Engine.GameEngine': [
                        'ServerActors=Utils.Package',
                        'ServerActors=Julia.Core',
                   ],
                   'Julia.Core': [
                       'Enabled=True',
                   ]
               }),
        ServerX('swat4tss', '/home/swat/swat4tss',
                revision='origin/server/coopx',
                settings={
                    'Engine.GameEngine': [
                        'ServerActors=Utils.Package',
                        'ServerActors=Julia.Core',
                    ],
                    'Julia.Core': [
                        'Enabled=True',
                    ]
                })
    ]

env.settings = Settings()
