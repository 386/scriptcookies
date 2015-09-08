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
        return "%.2f%s%s" % (num, 'Y', suffix)


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

    # Total Requests
    @query
    def get_total_requests(self):
        return 'hits.total'

    # Unique Visitors
    @query
    def get_unique_visitors(self):
        def parser(result):
            return len(result["aggregations"]["unique_visitors"]["buckets"])

        aggs = {
            "unique_visitors": {
                "terms": {
                    "field": "clientip",
                    "size": 0
                }
            }
        }

        return locals()

    # all referrers
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

    # Unique files
    @query
    def get_unique_files(self):

        def parser(result):
            return len(result["aggregations"]["unique_files"]["buckets"])

        aggs = {
            "unique_files": {
                "terms": {
                    "field": "request",
                    "size": 0
                }
            }
        }
        return locals()

    # unique 404
    @query
    def get_unique_404(self):
        def parser(result):
            return len(result["aggregations"]["response_404"]["buckets"])

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
                    "field": "request.raw",
                    "size": 0
                }
            }
        }
        return locals()

    # total band width
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

    # Top Requested Files sorted by band_width
    @query
    def requested_files(self, aggs_size=100, order={"band_width": "desc"}):

        def parser(result):
            buckets = result["aggregations"]["referrers"]["buckets"]
            res = []
            for b in buckets:
                res.append({
                    "url": b["key"],
                    "hits": b["doc_count"],
                    "band_width": Utils.human_readable(b["band_width"]["value"])
                })

            return res

        aggs = {
            "referrers": {
                "terms": {
                    "field": "request.raw",
                    "size": aggs_size,
                    "order": order
                },
                "aggs": {
                    "band_width":
                    {
                        "sum": {
                            "field": "bytes"
                        }
                    },
                }
            }
        }

        return locals()

    # Top 404 Not Found URLs sorted by band_width
    @query
    def http_404_urls(self, aggs_size=100, order={"band_width": "desc"}):

        def parser(result):
            buckets = result["aggregations"]["referrers"]["buckets"]
            res = []
            for b in buckets:
                res.append({
                    "url": b["key"],
                    "hits": b["doc_count"],
                    "band_width": Utils.human_readable(b["band_width"]["value"])
                })

            return res

        filtered_dict = {
            "filter": {
                "term": {
                    "response": "404"
                }
            }
        }

        aggs = {
            "referrers": {
                "terms": {
                    "field": "request.raw",
                    "size": aggs_size,
                    "order": order
                },
                "aggs": {
                    "band_width":
                        {
                            "sum": {
                                "field": "bytes"
                            }
                        },
                }
            }
        }

        return locals()

    # Top Hosts sorted by band_width
    @query
    def hosts(self, aggs_size=100, order={"band_width": "desc"}):

        def parser(result):
            buckets = result["aggregations"]["referrers"]["buckets"]
            res = []
            for b in buckets:
                res.append({
                    "ip": b["key"],
                    "hits": b["doc_count"],
                    "band_width": Utils.human_readable(b["band_width"]["value"]),
                    "country_name": b['country_name']["buckets"][0]["key"] if b['country_name']["buckets"] else "",
                    "city_name": b['city_name']["buckets"][0]["key"] if b['city_name']["buckets"] else ""
                })

            return res

        aggs = {
            "referrers": {
                "terms": {
                    "field": "clientip",
                    "size": aggs_size,
                    "order": order
                },
                "aggs": {
                    "band_width":
                        {
                            "sum": {
                                "field": "bytes"
                            }
                        },
                    # FIXME: find a good way to display city_name and
                    # country_name
                    "city_name": {
                            "terms": {
                                "field": "geoip.city_name"
                            }
                            },
                    "country_name": {
                        "terms": {
                            "field": "geoip.country_name"
                        }
                            }
                }
            }
        }

        return locals()

    @query
    def agents(self):
        aggs = {
            "agents": {
                "terms": {
                    "field": "agent.raw",
                }
            }
        }

        return locals()

    @query
    def http_status_codes(self):
        aggs = {
            "responses": {
                "terms": {
                    "field": "response",
                }
            }
        }
        return locals()

if __name__ == "__main__":
    overall = OverallSearch()
    # print overall.get_total_requests()
    # print overall.get_unique_visitors()
    # Utils.pd(overall.get_band_width())
    Utils.pd(overall.get_unique_404())
