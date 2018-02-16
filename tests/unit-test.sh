#!/bin/bash

image_name=${1:? $(basename $0) IMAGE_NAME VERSION needed}
version=${2:-latest}

ret=0
echo "Check docker-compose config"
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

echo "Check Nginx config"
docker-compose run --name "test-front" --rm front nginx -t
test_result=$?
if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] nginx config check [test_80.conf]"
else
  echo "[FAILED] nginx config check [test_80.conf]"
  ret=1
fi

exit $ret
