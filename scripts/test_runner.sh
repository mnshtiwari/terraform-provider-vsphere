#!/bin/bash

main () {
  eCode=0
  testList=$(TF_ACC=1 go test github.com/terraform-providers/terraform-provider-vsphere/vsphere | grep "\-\-\- FAIL" | awk '{ print $3 }' | grep TestAcc$1_)
  for testName in $testList; do 
    runTest $testName  || eCode=1
  done
  exit $eCode
}

runTest () {
  for try in {1..2}; do
    res=$(TF_ACC=1 go test github.com/terraform-providers/terraform-provider-vsphere/vsphere -v -count=1 -run="$1\$" -timeout 240m)
    if grep PASS <<< "$res" &> /dev/null; then
      break
    else
      revertAndWait
      sleep 30
      return 1
    fi
  done
  echo "$res"
  return 0
}


revertAndWait () {
  $GOPATH/src/github.com/terraform-providers/terraform-provider-vsphere/scripts/esxi_restore_snapshot.sh $VSPHERE_ESXI_SNAPSHOT
  sleep 30
  until curl -k "https://$VSPHERE_SERVER/rest/vcenter/datacenter" -i -m 10 2> /dev/null | grep "401 Unauthorized" &> /dev/null; do
    sleep 30
  done
}

main $1
