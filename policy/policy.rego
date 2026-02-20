package policy

# Required evidence predicate slugs that must be present before promotion.
# Modify this set to add/remove required evidence types for your organization.
expected_predicate_slugs := {"test-results", "sonarqube", "build-signature"}

# Collect all predicateSlugs found across artifacts in the Release Bundle
found_predicate_slugs := artifact_slugs | build_slugs | bundle_slugs

artifact_slugs := {slug |
    some i, j
    slug := input.data.releaseBundleVersion.getVersion.artifactsConnection.edges[i].node.evidenceConnection.edges[j].node.predicateSlug
}

build_slugs := {slug |
    some k, l
    slug := input.data.releaseBundleVersion.getVersion.fromBuilds[k].evidenceConnection.edges[l].node.predicateSlug
}

bundle_slugs := {slug |
    some m
    slug := input.data.releaseBundleVersion.getVersion.evidenceConnection.edges[m].node.predicateSlug
}

found := [slug | slug := found_predicate_slugs[_]]
not_found := [slug | slug := expected_predicate_slugs[_]; not found_predicate_slugs[slug]]

approved if {
    count({slug | slug := expected_predicate_slugs[_]; slug != ""}) == count(found_predicate_slugs & expected_predicate_slugs)
}

output := {
    "approved": approved,
    "found": found,
    "not_found": not_found,
    "message": sprintf("Evidence check: %d/%d required predicates found", [count(found_predicate_slugs & expected_predicate_slugs), count(expected_predicate_slugs)]),
}

default approved = false
default output = {"approved": false, "found": [], "not_found": [], "message": "Evidence verification failed"}
