#!/usr/bin/env python3

import argparse
import json
import yaml


def init_fcc(data={}):
    data.update({
        'variant': 'fcos',
        'version': '1.0.0',
        'storage': {'files': []},
        'systemd': {'units': []}
    })
    return data


def add_service(services, service):
    with open(service) as f:
        services.append({
            'name': 'run-coreos-installer.service',
            'enabled': True,
            'contents': f.read()
        })


def add_run_script(files, runscript):
    with open(runscript) as f:
        files.append({
            'path': '/usr/local/bin/run-coreos-installer',
            'mode': 0o755,
            'contents': {
                'inline': f.read()
            }
        })


def add_config(files, config):
    with open(config) as f:
        files.append({
            'path': '/home/core/config.ign',
            'mode': 0o644,
            'contents': {
                'inline': f.read()
            }
        })


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--runscript', default='run-coreos-installer')
    parser.add_argument(
        '--config', default='mycoreos.ign')
    parser.add_argument(
        '--service', default='run-coreos-installer.service')
    parser.add_argument(
        '--outfile', default='bootstrap.fcc')

    args = parser.parse_args()

    data = init_fcc()
    services = data['systemd']['units']
    add_service(services, args.service)
    files = data['storage']['files']
    add_run_script(files, args.runscript)
    add_config(files, args.config)
    with open(args.outfile, 'w') as g:
        yaml.dump(data, g)


if __name__ == "__main__":
    main()
