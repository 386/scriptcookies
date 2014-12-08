#!/usr/bin/env python
# -*- coding: utf-8 -*-
from elasticsearch import Elasticsearch
import json
import functools
import logging
ES_INDEX = "qiniu"
DOC_TYPE = "appstore"
DEBUG = False

logger = logging.getLogger("elasticsearch").addHandler(logging.StreamHandler())


class Utils():

    """pretty print dict"""
    @staticmethod
    def pd(d):
        print json.dumps(d, indent=4)

    @staticmethod
    def human_readable(num, suffix='B'):
        for unit in ['', 'K', 'M', 'G', 'T', 'P', 'E', 'Z']:
            if abs(num) < 1024.0:
                return "%3.2f%s%s" % (num, unit, suffix)
            num /= 1024.0
        return "%.2f%s%s" % (num, 'Yi', suffix)


def query(f):
    @functools.wraps(f)
    def wrapped(*args, **kwargs):
        query_info = f(*args, **kwargs)
        if isinstance(query_info, str):
            query_info = dict(path=query_info)
        assert isinstance(query_info, dict),\
            'Should dict instance returned, not %s: %s' % (
                type(query_info), query_info)
        self = query_info.pop('self', args[0])
        return self.query(**query_info)
    return wrapped


class BaseSearch():

    query_all = {
        "query": {
            "match_all": {}
        }
    }

    def __init__(self, index=ES_INDEX, doc_type=DOC_TYPE, hosts=None, **kwargs):
        self.es = Elasticsearch(hosts, **kwargs)
        self.index = index
        self.doc_type = doc_type

    def query(self, filtered_dict=query_all, aggs={}, size=0, path='', parser=None, **kwargs):
        query_body = self.set_query_body(filtered_dict, aggs, size)
        result = self.es.search(
            index=self.index, doc_type=self.doc_type, body=query_body)
        # if DEBUG:
        if True:
            print "=====query body====="
            Utils.pd(query_body)
            print "=====query result====="
            Utils.pd(result)
        if path:
            for attr in path.split('.'):
                result = result.get(attr)
                if result is None:
                    break
        if callable(parser):
            return parser(result)
        return result

    def set_query_body(self, filtered_dict, aggs, size):
        '''
        Use filters instead of query to improve search speed

        http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-filtered-query.html

        * Filters do not score so they are faster to execute than queries
        * Filters can be cached in memory allowing repeated search executions to be significantly faster than queries
        '''
        query_body = {
            "query": {
                "filtered": filtered_dict
            },
            "aggs": aggs,
            "size": size,
        }
        return query_body


class OverallSearch(BaseSearch):

    @query
    def get_total_requests(self):
        return 'hits.total'

    # FIXME: result may be not correct
    @query
    def get_unique_visitors(self):
        aggs = {
            "unique_visitors": {
                "cardinality": {
                    "field": "clientip",
                }
            }
        }

        return locals()

    @query
    def get_referrers(self):

        def parser(result):
            buckets = result["aggregations"]["referrers"]["buckets"]
            res = []
            for b in buckets:
                res.append({
                    "referrer": b["key"],
                    "count": b["doc_count"]
                })
            return res

        filtered_dict = {
            "filter": {
                "not": {
                    "term": {
                        "referrer.raw": "-"
                    }
                }
            }
        }

        aggs = {
            "referrers": {
                "terms": {
                    "field": "referrer.raw"
                }
            }
        }

        return locals()

    # FIXME: result may be not correct
    @query
    def get_unique_files(self):
        aggs = {
            "unique_files": {
                "cardinality": {
                    "field": "request",
                }
            }
        }
        return locals()

    # FIXME: result may be not correct
    @query
    def get_unique_404(self):
        filtered_dict = {
            "filter": {
                "term": {
                    "response": "404"
                }
            }
        }
        aggs = {
            "response_404": {
                "terms": {
                    "field": "request",
                }
            }
        }
        return locals()

    @query
    def get_band_width(self):

        def parser(result):
            return {"band_width":
                    Utils.human_readable(
                        result["aggregations"]["band_width"]["value"])
                    }

        aggs = {
            "band_width": {
                "sum": {
                    "field": "bytes"
                }
            }

        }

        return locals()

if __name__ == "__main__":
    overall = OverallSearch()
    # print overall.get_total_requests()
    # print overall.get_unique_visitors()
    Utils.pd(overall.get_band_width())
