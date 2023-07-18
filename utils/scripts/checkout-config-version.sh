#!/bin/bash

woorl -s "../../damsel/proto/domain_config.thrift" "http://dominant:8022/v1/domain/repository" Repository Checkout "{\"head\":{}}" | grep version
