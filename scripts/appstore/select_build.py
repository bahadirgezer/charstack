#!/usr/bin/env python3
import argparse
import json
import sys


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Select an App Store Connect build from a builds list payload."
    )
    parser.add_argument("--marketing-version", required=True)
    parser.add_argument("--build-number")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    payload = json.load(sys.stdin)
    items = payload.get("data") or []
    included = payload.get("included") or []

    pre_release_versions = {
        item.get("id", ""): (item.get("attributes") or {}).get("version", "")
        for item in included
        if item.get("type") == "preReleaseVersions"
    }

    selected = None
    for item in items:
        attrs = item.get("attributes") or {}
        if args.build_number and attrs.get("version") != args.build_number:
            continue

        rel = ((item.get("relationships") or {}).get("preReleaseVersion") or {}).get("data") or {}
        pre_release_id = rel.get("id", "")
        marketing_version = pre_release_versions.get(pre_release_id, "")
        if marketing_version != args.marketing_version:
            continue

        selected = item
        break

    if selected is None:
        print("||")
        return 0

    attrs = selected.get("attributes") or {}
    print(
        "{}|{}|{}".format(
            selected.get("id", ""),
            attrs.get("processingState", ""),
            attrs.get("version", ""),
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
