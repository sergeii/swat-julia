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
    version = '3.0-dev'
    git = 'git@git:games/swat'
    packages = [
        ('Utils', 'git@git:swat/swat-utils'),
        ('HTTP', 'git@git:swat/swat-http'),
        ('Julia', 'git@git:swat/swat-julia'),
    ]
    mods = [
        Mod('swat4', '/home/modder/swat4', revision='origin/modding/swat4'),
        ModX('swat4tss', '/home/modder/swat4tss', revision='origin/modding/swat4tss',
             content_dir='ContentExpansion'),
    ]

    server_settings = {
        'Engine.GameEngine': [
            'ServerActors=Utils.Package',
            'ServerActors=Julia.Core',
        ],
        'Julia.Tracker': [
            'Enabled=True',
            'Key=1234',
            'URL=http://swat4stats.com/stream/',
            'Attempts=5',
            'Feedback=True',
            'Compatible=False',
        ],
        'Julia.VIP': [
            'Enabled=True',
            'VIPCustomHealth=1 1000 10000',
            'ExtraRoundTime=120',
            'ExtraRoundTimeLimit=1',
        ],
        'Julia.COOP': [
            'Enabled=True',
            'MissionEndTime=180',
            'IgnoreSpectators=True',
        ],
        'Julia.Whois': [
            'Enabled=True',
            'Key=demo',
            'URL=http://swat4stats.com/api/whois',
            'Auto=True',
            'Commands=lookup',
            'Commands=db',
        ],
        'Julia.Chatbot': [
            'Enabled=True',
            'ReplyDelay=0.5',
            'ReplyThreshold=0.0',

            r"Templates=*(hi|ello|hey|yo) *again*#*i*m back*",
            r"Replies=Welcome back!#Hi, where have you been?#Hi. I missed you.. NOT!#Hi, again...#Hey [b]%name%[\b].#Welcome back, [b]%name%[\b].#Hi [b]%name[\b]! It's nice to see you again.",

            r"Templates=*(hi|ello|hey|yo|morning|evening|noon|hiya) *(all|guys|every)*",
            r"Replies=Hello, fellow gamer. Enjoy your stay.#Hello [b]%name%[\b].#Hey [b]%name%[\b].#Hi!#Hello there, [b]%name%[\b].#Hey, what's up?#Greetings, [b]%name%[\b].#Welcome to the server, [b]%name%[\b].#Hi [b]%name%[\b]!#Hey [b]%name%[\b]. Have fun!#Hi [b]%name%[\b]. Follow the rules and have fun!#Hiya [b]%name%[\b].",

            r"Templates=*(bb|bye|goodbye|cya|see y*|night|nite|gn) *(all|guys)*#*(have*go|gtg|g2g|got*go)( *|)",
            r"Replies=Goodbye [b]%name%[\b]. Take care.#See you later, [b]%name%[\b].#Bye.#See you later.#See you, [b]%name%[\b]. Be good.#Bye.#See ya, [b]%name%[\b]. Keep your nose clean.#Goodbye [b]%name%[\b], come back soon!#So long, [b]%name%[\b]. See you later.",
        ],
        'Julia.Stats': [
            'Enabled=True',

            'VariableStats=HIGHEST_HITS',
            'VariableStats=LOWEST_HITS',
            'VariableStats=HIGHEST_TEAM_HITS',
            'VariableStats=LOWEST_TEAM_HITS',
            'VariableStats=HIGHEST_AMMO_FIRED',
            'VariableStats=LOWEST_AMMO_FIRED',
            'VariableStats=HIGHEST_ACCURACY',
            'VariableStats=LOWEST_ACCURACY',
            'VariableStats=HIGHEST_NADE_HITS',
            'VariableStats=LOWEST_NADE_HITS',
            'VariableStats=HIGHEST_NADE_TEAM_HITS',
            'VariableStats=LOWEST_NADE_TEAM_HITS',
            'VariableStats=HIGHEST_NADE_THROWN',
            'VariableStats=LOWEST_NADE_THROWN',
            'VariableStats=HIGHEST_NADE_ACCURACY',
            'VariableStats=LOWEST_NADE_ACCURACY',
            'VariableStats=HIGHEST_KILL_DISTANCE',
            'VariableStats=LOWEST_KILL_DISTANCE',
            'VariableStats=HIGHEST_SCORE',
            'VariableStats=LOWEST_SCORE',
            'VariableStats=HIGHEST_KILLS',
            'VariableStats=LOWEST_KILLS',
            'VariableStats=HIGHEST_ARRESTS',
            'VariableStats=LOWEST_ARRESTS',
            'VariableStats=HIGHEST_ARRESTED',
            'VariableStats=LOWEST_ARRESTED',
            'VariableStats=HIGHEST_TEAM_KILLS',
            'VariableStats=LOWEST_TEAM_KILLS',
            'VariableStats=HIGHEST_SUICIDES',
            'VariableStats=LOWEST_SUICIDES',
            'VariableStats=HIGHEST_DEATHS',
            'VariableStats=LOWEST_DEATHS',
            'VariableStats=HIGHEST_KILL_STREAK',
            'VariableStats=LOWEST_KILL_STREAK',
            'VariableStats=HIGHEST_ARREST_STREAK',
            'VariableStats=LOWEST_ARREST_STREAK',
            'VariableStats=HIGHEST_DEATH_STREAK',
            'VariableStats=LOWEST_DEATH_STREAK',
            'VariableStats=HIGHEST_VIP_CAPTURES',
            'VariableStats=LOWEST_VIP_CAPTURES',
            'VariableStats=HIGHEST_VIP_RESCUES',
            'VariableStats=LOWEST_VIP_RESCUES',
            'VariableStats=HIGHEST_BOMBS_DEFUSED',
            'VariableStats=LOWEST_BOMBS_DEFUSED',
            'VariableStats=HIGHEST_CASE_KILLS',
            'VariableStats=LOWEST_CASE_KILLS',
            'VariableStats=HIGHEST_REPORTS',
            'VariableStats=LOWEST_REPORTS',
            'VariableStats=HIGHEST_HOSTAGE_ARRESTS',
            'VariableStats=LOWEST_HOSTAGE_ARRESTS',
            'VariableStats=HIGHEST_HOSTAGE_HITS',
            'VariableStats=LOWEST_HOSTAGE_HITS',
            'VariableStats=HIGHEST_HOSTAGE_INCAPS',
            'VariableStats=LOWEST_HOSTAGE_INCAPS',
            'VariableStats=HIGHEST_HOSTAGE_KILLS',
            'VariableStats=LOWEST_HOSTAGE_KILLS',
            'VariableStats=HIGHEST_ENEMY_ARRESTS',
            'VariableStats=LOWEST_ENEMY_ARRESTS',
            'VariableStats=HIGHEST_ENEMY_INCAPS',
            'VariableStats=LOWEST_ENEMY_INCAPS',
            'VariableStats=HIGHEST_ENEMY_KILLS',
            'VariableStats=LOWEST_ENEMY_KILLS',
            'VariableStats=HIGHEST_ENEMY_INCAPS_INVALID',
            'VariableStats=LOWEST_ENEMY_INCAPS_INVALID',
            'VariableStats=HIGHEST_ENEMY_KILLS_INVALID',
            'VariableStats=LOWEST_ENEMY_KILLS_INVALID',

            'VariableStatsLimit=5',

            'FixedStats=HIGHEST_HITS',
            'FixedStats=LOWEST_HITS',

            'PlayerStats=ACCURACY',
            'PlayerStats=HITS',
            'PlayerStats=AMMO_FIRED',
            'PlayerStats=NADE_ACCURACY',
            'PlayerStats=NADE_HITS',
            'PlayerStats=NADE_THROWN',
            'PlayerStats=TEAM_HITS',
            'PlayerStats=NADE_TEAM_HITS',

            'MinTimeRatio=0',
        ],
        'Julia.Admin': [
            'Enabled=True',
            'DisallowVIPVoice=True',
            'AutoBalance=True',
            'AutoBalanceTime=10',
            'AutoBalanceAction=',
            'AutoBalanceActionLimit=2',
            'DisallowWords=f*ck',
            'DisallowWordsAction=kick',
            'DisallowWordsActionLimit=2',
            'DisallowWordsIgnoreAdmins=False',
            'DisallowWordsAlertAdmins=True',
            'DisallowNames=*fu*ck*',
            'DisallowNames=cun*t',
            'DisallowNamesAction=forcemute',
            'DisallowNamesActionTime=10',
            'DisallowNamesActionWarnings=50',
            'ProtectNames=|MYT|* pass',
            'ProtectNames=serge    lol   ',
            'ProtectNames=foo   bar   ham ',
            'ProtectNamesAction=kickban',
            'ProtectNamesActionTime=300',
            'ProtectNamesActionWarnings=100',
            'ProtectNamesIgnoreAdmins=True',
            'FilterText=False',
            'FilterTextIgnoreAdmins=True',
            'FriendlyFire=(Weapons="TaSEr stun Gun",IgnoreAdmins=True,Alert=True,Action="kick",ActionLimit=2)',
            'FriendlyFire=(Weapons="Pepper Spray",Alert=True,ActionLimit=5,Action="forcelesslethal")',
            'FriendlyFire=(Weapons="Pepper-ball",Alert=True,ActionLimit=10,Action="forcelesslethal")',
            'FriendlyFire=(Weapons="Flashbang,Stinger",Alert=True,ActionLimit=5,Action="forcelesslethal")',
            'FriendlyFire=(Weapons="Less Lethal Shotgun",Alert=True,ActionLimit=5,Action="forcenoweapons")',
        ],
    }
    servers = [
        Server('swat4', '/home/swat/swat4',
               revision='570cc86',
               settings=server_settings),
        ServerX('swat4tss', '/home/swat/swat4tss',
                revision='4739d14',
                settings=server_settings)
    ]

env.settings = Settings()
