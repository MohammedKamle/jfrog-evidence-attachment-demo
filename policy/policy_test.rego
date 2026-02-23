package policy

test_approved_when_all_evidence_present if {
    approved with input as {
        "data": {
            "releaseBundleVersion": {
                "getVersion": {
                    "artifactsConnection": {
                        "edges": [
                            {
                                "node": {
                                    "evidenceConnection": {
                                        "edges": [
                                            {"node": {"predicateSlug": "test-results"}},
                                            {"node": {"predicateSlug": "sonarqube"}}
                                        ]
                                    }
                                }
                            }
                        ]
                    },
                    "fromBuilds": [
                        {
                            "evidenceConnection": {
                                "edges": [
                                    {"node": {"predicateSlug": "build-signature"}}
                                ]
                            }
                        }
                    ],
                    "evidenceConnection": {
                        "edges": []
                    }
                }
            }
        }
    }
}

test_not_approved_when_evidence_missing if {
    not approved with input as {
        "data": {
            "releaseBundleVersion": {
                "getVersion": {
                    "artifactsConnection": {
                        "edges": [
                            {
                                "node": {
                                    "evidenceConnection": {
                                        "edges": [
                                            {"node": {"predicateSlug": "test-results"}}
                                        ]
                                    }
                                }
                            }
                        ]
                    },
                    "fromBuilds": [],
                    "evidenceConnection": {
                        "edges": []
                    }
                }
            }
        }
    }
}
