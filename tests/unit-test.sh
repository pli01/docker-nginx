#!/bin/bash
set -x

export image_name=${1:? $(basename $0) IMAGE_NAME VERSION needed}
export VERSION=${2:-latest}
namespace=nginx
test_service=front

ret=0
echo "Check tests/docker-compose.yml config"
docker-compose -p ${namespace} config
test_result=$?
if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] docker-compose -p ${namespace} config"
else
  echo "[FAILED] docker-compose -p ${namespace} config"
  ret=1
fi

echo "Check Nginx version"
docker-compose -p ${namespace} run --name "test-front" --rm $test_service nginx -V
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
echo "# setup env test:"
test_compose=docker-compose.test.yml
test_service=front
test_config=test_80.conf
docker-compose -p ${namespace} -f $test_compose up -d --no-build $test_service
container=$(docker-compose -p ${namespace}  -f $test_compose ps -q $test_service)
docker cp $test_config ${container}:/etc/nginx/conf.d/default.conf

# run test
echo "# run test:"
docker-compose -p ${namespace}  -f $test_compose exec -T $test_service nginx -t
test_result=$?

# teardown
echo "# teardown:"
docker-compose -p ${namespace}  -f $test_compose stop
docker-compose -p ${namespace}  -f $test_compose rm -fv

if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] nginx config check [$test_config]"
else
  echo "[FAILED] nginx config check [$test_config]"
  ret=1
fi

exit $ret
