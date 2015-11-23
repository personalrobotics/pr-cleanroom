#!/usr/bin/env python
from __future__ import print_function
from urlparse import urlparse
import sys
import yaml

distribution = yaml.load(sys.stdin)

for repository_name, repository in distribution['repositories'].iteritems():
    url = urlparse(repository['source']['url'])

    if url.scheme == 'https' and url.netloc == 'github.com':
        path = url.path[1:] if url.path.startswith('/') else url.path
        repository['source']['url'] = 'git@{netloc:s}:{path:s}'.format(
            netloc=url.netloc, path=path)

yaml.dump(distribution, sys.stdout)
