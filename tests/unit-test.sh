#!/bin/bash

image_name=${1:? $(basename $0) IMAGE_NAME VERSION needed}
version=${2:-latest}

ret=0
echo "Check tests/docker-compose.yml config"
docker-compose config
test_result=$?
if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] docker-compose config"
else
  echo "[FAILED] docker-compose config"
  ret=1
fi

echo "Check Nginx version"
docker-compose run --name "test-front" --rm front nginx -V
test_result=$?
if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] nginx version"
else
  echo "[FAILED] nginx version"
  ret=1
fi

# test a small nginx config
echo "Check Nginx config"

# setup test
test_compose=docker-compose.test.yml
test_config=test_80.conf
docker-compose -f $test_compose up -d --no-build front
container=$(docker-compose  -f $test_compose ps  | awk ' NR > 2 { print $1 }')
docker cp $test_config ${container}:/etc/nginx/conf.d/default.conf

# run test
docker-compose  -f $test_compose exec front nginx -t
test_result=$?

# teardown
docker-compose  -f $test_compose stop
docker-compose  -f $test_compose rm -fv

if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] nginx config check [$test_config]"
else
  echo "[FAILED] nginx config check [$test_config]"
  ret=1
fi

exit $ret
