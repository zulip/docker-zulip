from io import StringIO
import os
import configparser
import secrets

def read_example_env():
    file_to_read = None
    if os.path.isfile('.env'):
        file_to_read = '.env'
    else:
        file_to_read = '.env.example'

    dummy_config = StringIO()
    dummy_config.write('[dummy]\n')
    dummy_config.write(open(file_to_read).read())
    dummy_config.seek(0, os.SEEK_SET)

    cp = configparser.ConfigParser()
    cp.read_file(dummy_config)
    return cp['dummy']

def set_if_expected(env, key, expected, value):
    if env[key] == expected:
        env[key] = value

def generate_and_set_secrets(env):
    set_if_expected(env, 'POSTGRES_PASSWORD', 'REPLACE_WITH_SECURE_POSTGRES_PASSWORD', secrets.token_hex(32))
    set_if_expected(env, 'MEMCACHED_PASSWORD', 'REPLACE_WITH_SECURE_MEMCACHED_PASSWORD', secrets.token_hex(32))
    set_if_expected(env, 'RABBITMQ_PASSWORD', 'REPLACE_WITH_SECURE_RABBITMQ_PASSWORD', secrets.token_hex(32))
    set_if_expected(env, 'REDIS_PASSWORD', 'REPLACE_WITH_SECURE_REDIS_PASSWORD', secrets.token_hex(32))
    set_if_expected(env, 'secret_key', 'REPLACE_WITH_SECURE_SECRET_KEY', ''.join(secrets.choice('abcdefghijklmnopqrstuvwxyz0123456789!@#$^&*(-_=+)') for i in range(50)))

def write_env(env):
    env_file = ''
    for key in env:
        env_file = f'{env_file}{key}={env[key]}\n'
    
    f = open('.env', 'w')
    f.write(env_file)
    f.close()

env = read_example_env()
generate_and_set_secrets(env)
write_env(env)
