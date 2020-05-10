# `bazel-dependency-manager`

Simple dependency management for Bazel.

## API

### `fetch_dependencies`
```
fetch_dependencies(
    {
        "<WORKSPACE_NAME>": {
            # "source" and "sources" are used to specify where to fetch the dependency from
            "source": "<URI>",
            "sources": ["<URI>"],
            "is_file": False, # Whether or not to use http_file
            "executable": False, # Executable implies is_file
            # Any extra keys and values - e.g. `sha256` - are passed directly to the underlying workspace
            # rule - which is usually http_archive or http_file.
            "<KEY>": "<VALUE>",
        }
    }
)
```

### Example Usage
```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "bazel_dependency_manager",
    urls = ["https://github.com/Slowki/bazel-dependency-manager/archive/ad9c621307dff1300303981dde0425795bd301e9.tar.gz"],
    strip_prefix = "bazel-dependency-manager-ad9c621307dff1300303981dde0425795bd301e9",
    sha256 = "9d1c2b2c2d1698fb7693d354a7c09f999fd2fe8d7a8c8aa1ea593e2c0902c054",
)

load("@bazel_dependency_manager//:repo_rules.bzl", "fetch_dependencies")
fetch_dependencies(
    {
        "rules_cc": {
            "source": "github:bazelbuild/rules_cc#8c31dd406cf17611d7962bee4680cbc4360219ed",
            "sha256": "072ebe7abf772ac73f862626427ed4a09bb0d5227cf4896d98bc41afdebd387b",
        },
        "rules_python": {
            "sources": [
                "github:bazelbuild/rules_python#a0fbf98d4e3a232144df4d0d80b577c7a693b570",
                "https://internal-mirror.corp.internal/rules_python/0fbf98d4e3a232144df4d0d80b577c7a693b570.tar.gz"
            ],
            "sha256": "76a8fd4e7eca2a3590f816958faa0d83c9b2ce9c32634c5c375bcccf161d3bb5",
        },
        "interal_library": {
            "sources": [
                "github:github.corp.internal/corp/interal_library#v1.2.3",
            ],
            "sha256": "<HASH>",
        },
        "system": {
            "source": "local:/",
            "build_file": "@//:BUILD",
        },
    },
)
```

## Supported URI Formats
* `http` & `https` - `https://site.tld/path/to/archive`
* `github` - `"github:organization/repository#version"` or `"github:github.corp.internal/organization/repository#version"`
* `gitlab` - `"gitlab:organization/repository#version"` or `"gitlab:gitlab.corp.internal/organization/repository#version"`
* `local` - `"local:/path/to/repository"`
