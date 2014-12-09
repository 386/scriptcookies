#!/usr/bin/env python
# -*- coding: utf-8 -*-
from elasticsearch import Elasticsearch
from elasticsearch.helpers import reindex

ELASTICSEARCH_ALIAS = 'qiniu'
ELASTICSEARCH_INDEX = 'qiniu_log'
ELASTICSEARCH_INDEX_NEW = 'qiniu_log_v1'
ELASTICSEARCH_TYPE = 'appstore'
es = Elasticsearch()


def init_qiniu_index():
    if es.indices.exists(ELASTICSEARCH_INDEX_NEW):
        print 'Delete index %s' % ELASTICSEARCH_INDEX_NEW
        es.indices.delete(ELASTICSEARCH_INDEX_NEW)

    # not_analyzed for referrer
    # http://www.elasticsearch.org/guide/en/elasticsearch/guide/current/aggregations-and-analysis.html
    settings = {
        "mappings": {
            ELASTICSEARCH_TYPE: {
                "properties": {
                    "bytes": {
                        "type": "long",
                    },
                    "response": {
                        "type": "integer",
                    },
                    "referrer": {
                        "type": "string",
                        "fields": {
                                "raw": {
                                    "type": "string",
                                    "index": "not_analyzed"
                                }
                        }
                    },
                    "request": {
                        "type": "string",
                        "fields": {
                            "raw": {
                                "type": "string",
                                "index": "not_analyzed"
                            }
                        }
                    },
                    "agent": {
                        "type": "string",
                        "fields": {
                            "raw": {
                                "type": "string",
                                "index": "not_analyzed"
                            }
                        }
                    },
                    "domain": {
                        "type": "string",
                        "fields": {
                            "raw": {
                                "type": "string",
                                "index": "not_analyzed"
                            }
                        }
                    },
                }
            }
        }
    }

    print 'Create new index %s with mappings' % ELASTICSEARCH_INDEX_NEW
    es.indices.create(ELASTICSEARCH_INDEX_NEW, body=settings)

    print "reindex"
    reindex(es, ELASTICSEARCH_INDEX, ELASTICSEARCH_INDEX_NEW)

    print "Create index alias: %s" % ELASTICSEARCH_ALIAS
    es.indices.put_alias(
        name=ELASTICSEARCH_ALIAS, index=ELASTICSEARCH_INDEX_NEW)

    update_body = {
        "actions": [
            {"remove": {
                "index": ELASTICSEARCH_INDEX, "alias": ELASTICSEARCH_ALIAS}}
        ]
    }
    print "Remove index: %s from alias: %s" % (ELASTICSEARCH_INDEX, ELASTICSEARCH_ALIAS)
    es.indices.update_aliases(update_body)

if __name__ == '__main__':
    init_qiniu_index()
