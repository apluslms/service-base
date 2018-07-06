# service-base

A base Docker images for all images using _single service per container_ principle.
Contains s6 init system.

## Layers

* base - just s6 init and utilities
* dbipc - postgresql and rabbitmq
* python3 - python3 environment on top of dbipc
