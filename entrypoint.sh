#!/bin/sh

set -e

composer self-update

php-fpm
