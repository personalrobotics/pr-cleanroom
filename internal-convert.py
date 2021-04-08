#!/usr/bin/env python
from __future__ import print_function
from urlparse import urlparse
import sys
import yaml
from future.utils import iteritems

distribution = yaml.load(sys.stdin, Loader=yaml.FullLoader)

for repository_name, repository in iteritems(distribution['repositories']):
    url = urlparse(repository['source']['url'])

    if url.scheme == 'https' and url.netloc == 'github.com':
        path = url.path[1:] if url.path.startswith('/') else url.path
        repository['source']['url'] = 'git@{netloc:s}:{path:s}'.format(
            netloc=url.netloc, path=path)

yaml.dump(distribution, sys.stdout)
