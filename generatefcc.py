#!/usr/bin/env python3

import argparse
import json
import yaml


def init_fcc(data={}):
    data.update({
        'variant': 'fcos',
        'version': '1.0.0',
        'storage': {'files': []}
    })
    return data


def add_ssh_authkey(data, sshkey):
    with open(sshkey) as f:
        data['passwd'] = {
            'users': [{
                'name': 'core',
                'ssh_authorized_keys': [f.read()]
            }]
        }


def add_root_cert(files, rootcert):
    with open(rootcert) as f:
        files.append({
            'path': '/etc/pki/ca-trust/source/anchors/myca.pem',
            'mode': 0o644,
            'contents': {
                'inline': f.read()
            }
        })


def add_daemon_json(files, mirror):
    daemon_data = {
        "registry-mirrors": [
            mirror
        ]
    }
    files.append({
        'path': '/etc/docker/daemon.json',
        'mode': 0o644,
        'contents': {
            'inline': json.dumps(daemon_data)
        }
    })


def add_hostname(files, name):
    files.append({
        'path': '/etc/hostname',
        'mode': 0o644,
        'contents': {
            'inline': name
        }
    })


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('name')
    parser.add_argument(
        '--rootcert', default='C:/Users/dogbe/Source/repos/mycerts/out/saved/rootcert.pem')
    parser.add_argument(
        '--sshkey', default='C:/Users/dogbe/.ssh/id_ed25519.pub')
    parser.add_argument(
        '--mirror', default='https://windforce.internal.dogbertai.net:5000')
    parser.add_argument(
        '--outfile', default='mycoreos.fcc')

    args = parser.parse_args()

    data = init_fcc()
    # with open('mycoreos.fcc') as f:
    #    data = yaml.safe_load(f)
    add_ssh_authkey(data, args.sshkey)
    files = data['storage']['files']
    add_root_cert(files, args.rootcert)
    add_daemon_json(files, args.mirror)
    add_hostname(files, args.name)
    with open(args.outfile, 'w') as g:
        yaml.dump(data, g)


if __name__ == "__main__":
    main()
