#!/bin/bash

set -o errexit
set -o pipefail
set -o errtrace

export CHARSET=UTF-8
export LANG=C.UTF-8

VERSION=${1}
shift 1

[ -z "${VERSION}" ] && { echo "No version specified"; exit -1; }

FIXTURE=$(cat <<END
{"ops": [
    {"insert": {"object": {"globals": {
        "ref": {},
        "data": {
            "system_account_set": {"value": {"id": 1}},
            "external_account_set": {"value": {"id": 1}},
            "inspector": {"value": {"id": 1}}
        }
    }}}},
    {"insert": {"object": {"system_account_set": {
        "ref": {"id": 1},
        "data": {
            "name": "Primary",
            "description": "Primary",
            "accounts": [
              {
                "key": {"symbolic_code": "RUB"},
                "value": {"settlement": $(./scripts/create-account.sh RUB)}
              }
            ]
        }
    }}}},
    {"insert": {"object": {"external_account_set": {
        "ref": {"id": 1},
        "data": {
            "name": "Primary",
            "description": "Primary",
            "accounts": [
              {
                "key": {"symbolic_code": "RUB"},
                "value": {
                  "income": $(./scripts/create-account.sh RUB),
                  "outcome": $(./scripts/create-account.sh RUB)
                }
              }
            ]
          }
    }}}},
    {"insert": {"object": {"inspector": {
        "ref": {"id": 1},
        "data": {
          "name": "Fraudbusters",
          "description": "Fraudbusters!",
          "proxy": {"ref": {"id": 5}, "additional": []},
          "fallback_risk_score": "high"
        }
      }}}},
    {"insert": {"object": {"term_set_hierarchy": {
        "ref": {"id": 1},
        "data": {
            "term_sets": [
              {
                "action_time": [],
                "terms": {
                  "payments": {
                    "currencies": {
                      "value": [
                        {"symbolic_code": "RUB"}
                      ]
                    },
                    "categories": {
                      "value": [
                        {"id": 1}
                      ]
                    },
                    "payment_methods": {
                      "value": [
                        {
                          "id": {
                            "bank_card": {
                              "payment_system": {"id": "VISA"},
                              "is_cvv_empty": false
                            }
                          }
                        }
                      ]
                    },
                    "cash_limit": {
                      "decisions": [
                        {
                          "if_": {
                            "condition": {
                              "currency_is": {
                                "symbolic_code": "RUB"
                              }
                            }
                          },
                          "then_": {
                            "value": {
                              "upper": {
                                "exclusive": {
                                  "amount": 4200000,
                                  "currency": {
                                    "symbolic_code": "RUB"
                                  }
                                }
                              },
                              "lower": {
                                "inclusive": {
                                  "amount": 1000,
                                  "currency": {
                                    "symbolic_code": "RUB"
                                  }
                                }
                              }
                            }
                          }
                        }
                      ]
                    },
                    "fees": {
                      "decisions": [
                        {
                          "if_": {
                            "condition": {
                              "currency_is": {
                                "symbolic_code": "RUB"
                              }
                            }
                          },
                          "then_": {
                            "value": [
                              {
                                "source": {
                                  "merchant": "settlement"
                                },
                                "destination": {
                                  "system": "settlement"
                                },
                                "volume": {
                                  "share": {
                                    "parts": {
                                      "p": 45,
                                      "q": 1000
                                    },
                                    "of": "operation_amount"
                                  }
                                }
                              }
                            ]
                          }
                        }
                      ]
                    },
                    "holds": {
                      "payment_methods": {
                        "value": [
                          {
                            "id": {
                              "bank_card": {
                                "payment_system": {"id": "VISA"},
                                "is_cvv_empty": false
                              }
                            }
                          }
                        ]
                      },
                      "lifetime": {
                        "value": {
                          "seconds": 10000
                        }
                      }
                    },
                    "refunds": {
                      "payment_methods": {
                        "value": [
                          {
                            "id": {
                              "bank_card": {
                                "payment_system": {"id": "VISA"},
                                "is_cvv_empty": false
                              }
                            }
                          }
                        ]
                      },
                      "fees": {
                        "value": []
                      },
                      "eligibility_time": {
                        "value": {
                          "years": 1
                        }
                      },
                      "partial_refunds": {
                        "cash_limit": {
                          "decisions": [
                            {
                              "if_": {
                                "condition": {
                                  "currency_is": {
                                    "symbolic_code": "RUB"
                                  }
                                }
                              },
                              "then_": {
                                "value": {
                                  "upper": {
                                    "exclusive": {
                                      "amount": 10000000,
                                      "currency": {
                                        "symbolic_code": "RUB"
                                      }
                                    }
                                  },
                                  "lower": {
                                    "inclusive": {
                                      "amount": 1000,
                                      "currency": {
                                        "symbolic_code": "RUB"
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          ]
                        }
                      }
                    }
                  },
                  "recurrent_paytools": {
                    "payment_methods": {
                      "value": [
                        {
                          "id": {
                            "bank_card": {
                              "payment_system": {"id": "VISA"},
                              "is_cvv_empty": false
                            }
                          }
                        }
                      ]
                    }
                  }
                }
              }
            ]
          }
    }}}},
    {"insert": {"object": {"contract_template": {
        "ref": {"id": 1},
        "data": {"terms": {"id": 1}}
    }}}},
    {"insert": {"object": {"currency": {
        "ref": {"symbolic_code": "RUB"},
        "data": {
            "name": "Russian rubles",
            "numeric_code": 643,
            "symbolic_code": "RUB",
            "exponent": 2
        }
    }}}},
    {"insert": {"object": {"category": {
        "ref": {"id": 1},
        "data": {
            "name": "Basic test category",
            "description": "Basic test category for mocketbank provider",
            "type": "test"
        }
    }}}},
    {"insert": {"object": {"bank_card_category": {
        "ref": {"id": 1},
        "data": {
            "name": "CATEGORY1",
            "description": "ok",
            "category_patterns": [
              "*SOMECATEGORY*"
            ]
          }
    }}}},
    {"insert": {"object": {"bank": {
        "ref": {"id": 1},
        "data": {
            "name": "Bank 1",
            "description": "Bank 1",
            "binbase_id_patterns": [
              "*SOMEBANK*"
            ],
            "bins": [
              "123456"
            ]
          }
    }}}},
    {"insert": {"object": {"provider": {
        "ref": {"id": 1},
        "data": {
            "name": "Mocketbank",
            "description": "Mocketbank",
            "proxy": {
              "ref": {"id": 1},
              "additional": []
            },
            "accounts": [
              {
                "key": {"symbolic_code": "RUB"},
                "value": {"settlement": $(./scripts/create-account.sh RUB)}
              }
            ],
            "terms": {
              "payments": {
                "currencies": {
                  "value": [
                    {"symbolic_code": "RUB"}
                  ]
                },
                "categories": {
                  "value": [
                    {"id": 1}
                  ]
                },
                "payment_methods": {
                  "value": [
                    {
                      "id": {
                        "bank_card": {
                          "payment_system": {"id": "VISA"},
                          "is_cvv_empty": false
                        }
                      }
                    }
                  ]
                },
                "cash_limit": {
                  "decisions": [
                    {
                      "if_": {
                        "condition": {
                          "currency_is": {
                            "symbolic_code": "RUB"
                          }
                        }
                      },
                      "then_": {
                        "value": {
                          "upper": {
                            "exclusive": {
                              "amount": 10000000,
                              "currency": {
                                "symbolic_code": "RUB"
                              }
                            }
                          },
                          "lower": {
                            "inclusive": {
                              "amount": 1000,
                              "currency": {
                                "symbolic_code": "RUB"
                              }
                            }
                          }
                        }
                      }
                    }
                  ]
                },
                "cash_flow": {
                  "decisions": [
                    {
                      "if_": {
                        "condition": {
                          "payment_tool": {
                            "bank_card": {
                              "definition": {
                                "payment_system": {
                                  "payment_system_is": {"id": "VISA"}
                                }
                              }
                            }
                          }
                        }
                      },
                      "then_": {
                        "value": [
                          {
                            "source": {
                              "provider": "settlement"
                            },
                            "destination": {
                              "merchant": "settlement"
                            },
                            "volume": {
                              "share": {
                                "parts": {
                                  "p": 1,
                                  "q": 1
                                },
                                "of": "operation_amount"
                              }
                            }
                          },
                          {
                            "source": {
                              "system": "settlement"
                            },
                            "destination": {
                              "provider": "settlement"
                            },
                            "volume": {
                              "share": {
                                "parts": {
                                  "p": 15,
                                  "q": 1000
                                },
                                "of": "operation_amount"
                              }
                            }
                          }
                        ]
                      }
                    }
                  ]
                },
                "holds": {
                  "lifetime": {
                    "value": {
                      "seconds": 10000
                    }
                  }
                },
                "refunds": {
                  "cash_flow": {
                    "value": [
                      {
                        "source": {
                          "merchant": "settlement"
                        },
                        "destination": {
                          "provider": "settlement"
                        },
                        "volume": {
                          "share": {
                            "parts": {
                              "p": 1,
                              "q": 1
                            },
                            "of": "operation_amount"
                          }
                        }
                      }
                    ]
                  },
                  "partial_refunds": {
                    "cash_limit": {
                      "decisions": [
                        {
                          "if_": {
                            "condition": {
                              "currency_is": {
                                "symbolic_code": "RUB"
                              }
                            }
                          },
                          "then_": {
                            "value": {
                              "upper": {
                                "exclusive": {
                                  "amount": 10000000,
                                  "currency": {
                                    "symbolic_code": "RUB"
                                  }
                                }
                              },
                              "lower": {
                                "inclusive": {
                                  "amount": 1000,
                                  "currency": {
                                    "symbolic_code": "RUB"
                                  }
                                }
                              }
                            }
                          }
                        }
                      ]
                    }
                  }
                }
              },
              "recurrent_paytools": {
                "cash_value": {
                  "decisions": [
                    {
                      "if_": {
                        "condition": {
                          "currency_is": {
                            "symbolic_code": "RUB"
                          }
                        }
                      },
                      "then_": {
                        "value": {
                          "amount": 199,
                          "currency": {
                            "symbolic_code": "RUB"
                          }
                        }
                      }
                    }
                  ]
                },
                "categories": {
                  "value": [
                    {"id": 1}
                  ]
                },
                "payment_methods": {
                  "value": [
                    {
                      "id": {
                        "bank_card": {
                          "payment_system": {"id": "VISA"},
                          "is_cvv_empty": false
                        }
                      }
                    }
                  ]
                }
              }
            },
            "abs_account": "0000000001",
            "terminal": {
              "value": [
                {
                  "id": 1,
                  "priority": 1000
                }
              ]
            }
          }
    }}}},
    {"insert": {"object": {"payment_method": {
        "ref": {"id": {"bank_card": {"payment_system": {"id": "VISA"}}}},
        "data": {
            "name": "VISA",
            "description": "VISA bank cards"
        }
    }}}},
    {"insert": {"object": {"terminal": {
        "ref": {"id": 1},
        "data": {
            "name": "Mocketbank Test Acquiring",
            "description": "Mocketbank Test Acquiring",
            "provider_ref": {
              "id": 1
            },
            "options": {
              "TEST_OPTION": "111222"
            }
        }
    }}}},
    {"insert": {"object": {"proxy": {
        "ref": {"id": 1},
        "data": {
            "name": "Mocketbank Proxy",
            "description": "Mocked bank proxy for integration test purposes",
            "url": "http://proxy-mocketbank:8022/proxy/mocketbank",
            "options": {}
        }
    }}}},
    {"insert": {"object": {"proxy": {
        "ref": {
          "id": 5
        },
        "data": {
          "name": "Fraudbusters",
          "description": "Fraudbusters",
          "url": "http://fraudbusters:8022/fraud_inspector/v1",
          "options": []
        }
      }}}},
    {"insert": {"object": {"routing_rules": {
        "ref": {"id": 1},
        "data": {
            "name": "Роутинг по валюте",
            "decisions": {
              "candidates": [
                {
                  "allowed": {
                    "condition": {
                      "currency_is": {
                        "symbolic_code": "RUB"
                      }
                    }
                  },
                  "terminal": {
                    "id": 1
                  },
                  "priority": 1000
                }
              ]
            }
          }
    }}}},
    {"insert": {"object": {"routing_rules": {
        "ref": {"id": 2},
        "data": {
            "name": "Empty ruleset for prohibitions",
            "decisions": {
              "candidates": []
            }
          }
    }}}},
    {
      "insert": {
        "object": {
          "payment_system": {
            "ref": {"id": "VISA"},
            "data": {
              "name": "VISA",
              "validation_rules": [
                {"card_number": {"checksum": {"luhn": {}}}},
                {"card_number": {"ranges": [{"lower": 13, "upper": 13},{"lower": 16, "upper": 16}]}},
                {"cvc": {"length": {"lower": 3, "upper": 3}}},
                {"exp_date": {"exact_exp_date": {}}}
              ]
            }
          }
        }
      }
    },
    {"insert": {"object": {"payment_institution": {
        "ref": {"id": 1},
        "data": {
            "name": "Test Payment Institution",
            "system_account_set": {"value": {"id": 1}},
            "default_contract_template": {"value": {"id": 1}},
            "default_wallet_contract_template": {"value": {"id": 1}},
            "providers": {"value": [{"id": 1}]},
            "inspector": {"value": {"id": 1}},
            "realm": "test",
            "wallet_system_account_set": {"value": {"id": 1}},
            "residences": ["rus", "aus", "jpn"],
            "identity" : "1",
            "payment_routing_rules" : {"policies": {"id":1},"prohibitions": {"id":2}}
        }
    }}}}
]}
END
)

woorl -s "../damsel/proto/domain_config.thrift" "http://dominant:8022/v1/domain/repository" Repository Commit ${VERSION} "${FIXTURE}"

echo -e "\n"