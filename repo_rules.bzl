load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

def _filter_arguments(argument_dict, names):
    return {arg_name: arg_value for arg_name, arg_value in argument_dict.items() if arg_name not in names}

def _parse_github_like(source, default_host = "github.com"):
    """Parse a GitHub-like source.

    The sources are expected to be of the format [host/]<organization>/<repository>#<version>

    Returns:
        A tuple of (hostname, organization, repository, version)
    """
    sections = source.split("/")
    host = default_host
    if len(sections) == 3:
        host = sections[0]
        sections = sections[1:]
    if len(sections) != 2:
        fail("Expected a GitHub source url in the form [host/]<organization>/<repository>#<version>, like `foo/bar#v1.2.3`, received `{}`".format(source))

    repository, version = sections[-1].split("#", 2)
    organization = sections[0]

    return host, organization, repository, version

def _is_dotted_v(version_string):
    """A rough check for if a version is a dotted version starting with `v`, like `v1.2.3`."""
    return version_string.startswith("v") and all([char.isdigit() or char == "." for char in version_string[1:].elems()])

def _github_to_http(uri):
    """Convert a URI like "github:foo/bar" to an HTTP source."""
    host, organization, repository, version = _parse_github_like(uri)
    strip_prefix = "{}-{}".format(repository, version if not _is_dotted_v(version) else version.lstrip("v"))
    return ["https://{}/{}/{}/archive/{}.tar.gz".format(host, organization, repository, version)], strip_prefix

def _gitlab_to_http(uri):
    """Convert a URI like "gitlab:foo/bar" to an HTTP source."""
    host, organization, repository, version = _parse_github_like(uri, default_host = "gitlab.com")
    strip_prefix = "{}-{}".format(repository, version)
    return ["https://{host}/{org}/{repo}/-/archive/{version}/{repo}-{version}.tar.gz".format(host = host, org = organization, repo = repository, version = version)], strip_prefix

URI_HANDLERS = {
    "github": _github_to_http,
    "gitlab": _gitlab_to_http,
}

def fetch_dependencies(dependencies, uri_handlers = URI_HANDLERS):
    """Fetch dependencies.

    Arguments:
        dependencies: Mapping[str, Any]: An object describing the dependencies to fetch.
        uri_handlers: Mapping[str, Callable[[], Tuple[List[str], Optional[str]]]]: A mapping from URI
            prefix (eg. `http`) to a callable which returns a list of URLs to download from and an optional
            strip_prefix argument.
    """
    for name, value in dependencies.items():
        urls = []
        extra_arguments = _filter_arguments(value, ["source", "sources", "is_file", "strip_prefix"])
        strip_prefix = value.get("strip_prefix")
        download_repo_rule = http_archive
        if value.get("is_file") or value.get("executable"):
            download_repo_rule = http_file

        sources = value.get("sources", [])
        if type(sources) != "list":
            fail("Error in {}, sources must be a list of strings".format(name))

        if "source" in value:
            if type(value["source"]) != "string":
                fail("Error in {}, source must be a string".format(name))
            sources.append(value["source"])

        for source in sources:
            found = False
            if source.startswith("local:"):
                download_repo_rule = native.new_local_repository
                extra_arguments["path"] = source[6:]
                found = True
            for uri, handler in uri_handlers.items():
                if source.startswith(uri + ":"):
                    extra_urls, new_strip_prefix = handler(source[len(uri) + 1:])
                    urls.extend(extra_urls)
                    found = True
                    if strip_prefix == None:
                        strip_prefix = new_strip_prefix
                    break
            if not found:
                urls.append(source)

        if download_repo_rule != native.new_local_repository:
            extra_arguments["urls"] = urls
            extra_arguments["strip_prefix"] = strip_prefix

        download_repo_rule(
            name = name,
            **extra_arguments
        )
