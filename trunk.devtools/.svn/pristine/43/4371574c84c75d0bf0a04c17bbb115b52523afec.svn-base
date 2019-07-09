from common import error
import json
from urllib2 import (
    build_opener, HTTPBasicAuthHandler, HTTPError, quote, Request)
from httplib import CONFLICT, NOT_FOUND, UNAUTHORIZED


class ResourceConflict(Exception):
    pass


class ResourceNotFound(Exception):
    pass


class PasswordManager:
    def __init__(self, username_provider):
        self._username_provider = username_provider

    add_password = None  # Unused, but HTTPBasicAuthHandler wants it to be set

    def find_user_password(self, realm, authuri):
        username = self._username_provider.get_username()
        password = ""
        return username, password


class AuthenticatedRequest(Request):
    def __init__(self, method, url, data):
        headers = {}
        if data is not None:
            data = json.dumps(data)
            headers["Content-Type"] = "application/json"
        Request.__init__(self, url, data, headers)
        self._method = method

    def get_method(self):
        return self._method


class ServerApi:
    def __init__(self, api_url, username_provider):
        self._api_url = api_url
        self._username_provider = username_provider
        auth_handler = HTTPBasicAuthHandler(PasswordManager(username_provider))
        self._opener = build_opener(auth_handler)

    def add_mapping(self, pattern, group_id, triggers_katt2):
        return self._request("POST",
                             "mappings",
                             {"group_id": group_id,
                              "pattern": pattern,
                              "triggers_katt2": triggers_katt2})

    def delete_mapping(self, mapping_id):
        self._request("DELETE", "mappings/{0}".format(mapping_id))

    def get_mappings(self):
        return self._request("GET", "mappings")

    def get_mappings_by_group(self, group_id):
        return self._request("GET", "mappings/by-group/{0}".format(group_id))

    def get_mapping_by_id(self, mapping_id):
        return self._request("GET", "mappings/{0}".format(mapping_id))

    def update_mapping(self, mapping):
        self._request("PUT", "mappings/{0}".format(mapping["id"]), mapping)

    def add_group(self, name):
        return self._request("POST", "groups", {"name": name})

    def delete_group(self, group_id):
        self._request("DELETE", "groups/{0}".format(group_id))

    def get_groups(self):
        return self._request("GET", "groups")

    def get_group_by_id(self, group_id):
        return self._request("GET", "groups/{0}".format(group_id))

    def get_group_by_name(self, name):
        return self._request("GET", "groups/by-name/{0}".format(quote(name)))

    def update_group(self, group):
        self._request("PUT", "groups/{0}".format(group["id"]), group)

    #
    # Internals
    #

    def _request(self, method, path, data=None):
        url = self._api_url + path
        request = AuthenticatedRequest(method, url, data)
        try:
            response = self._opener.open(request)
            data = response.read()
            if data:
                return json.loads(data)
            else:
                return None
        except HTTPError as e:
            if e.code == NOT_FOUND:
                raise ResourceNotFound
            elif e.code == CONFLICT:
                raise ResourceConflict
            elif e.code == UNAUTHORIZED:
                username = self._username_provider.get_username()
                error("No such username: {0}".format(username))
            else:
                error("Unrecognized server response: {0} ({1})".format(e.code,
                                                                       e.msg))
