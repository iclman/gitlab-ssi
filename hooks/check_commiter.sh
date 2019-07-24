#!/bin/bash

#echo "### pre-receive check_committer hook"
NULL_SHA1="0000000000000000000000000000000000000000"    # 40 0's
TRASH="/dev/null"
Cmdlineopt=$@
cmd=""
CHECK_CONFIG_RC_FILE=""
ALLOWED_LIST=("spice" "root" "gcladmin")
errMsg="##
## Setting user.name of the commits above has a wrong format or
## the login is not allowed to commit on that repositiory.
##
## user.name MUST start by the login.
## for instance:
## login Firstname Lastname
## login Lastname Firstname
## login -- Firstname Lastname
## login -- Lastname Firstname
##
## e.g. : x123456 Martin DUPONT
##
## More help available at :
## https://wikigroupe.socgen/display/AT/GCL+-+GIT#GCL-GIT-Support (Rejet du push \"Commits from XXXX are not allowed\")
##\n"
status=0
# status=0 => OK
# status<>0 => KO : le hook rejette le push
function check_each_commit {
 # echo "inside check_each_commit"
  newsha=$1
  refname=$2
 # echo "newsha $newsha refname $refname "
  res=`git rev-list ${newsha} --reverse --not --all`
 # echo "res $res"
  stringArray=($res)
  for sha1 in "${stringArray[@]}"
  do
     objtype=`git cat-file -t $sha1`
    # echo "objtype $objtype sha1 $sha1"
     if  [[  $objtype =~ "commit" ]] || [[  $objtype =~ "COMMIT" ]]
     then
          result=` git log -1 --pretty=format:"%cn,%ae" $sha1 `
          cn=`echo $result | cut -d"," -f1`
          useremail=`echo $result | cut -d"," -f2`

          echo "check_each_commit : [$objtype] $sha1 by $cn and email $useremail\n"
       if [[ !  "${ALLOWED_LIST[*]}" == *"$cn"* ]]  # basically, we do not perform
                                                 # any verification on the
                                                 # commits made by members of allowed_list
       then
          if [[ -z $cn ]]
          then
              echo "### user.name is not defined for commit $sha1 "
              status=1
          fi
          if [[ $cn =~ ^a[0-9] ]] ||  [[ $cn =~ ^A[0-9] ]] ||  [[ $cn =~ ^x[0-9]  ]] ||  [[ $cn =~ ^X[0-9] ]]
          then
              echo  "correct $cn" >> /dev/null
          else
              echo "### user.name $cn is incorrect for commit $sha1"
              status=2
          fi

          if [[ ! "$useremail" =~ "@socgen.com" ]]
          then
               echo "### user.email \' $useremail \' is badly configured for commit $sha1"
              status=2
          fi
       fi
     fi
  done
}



while read line
do
  # echo "reading: $line"
   array=($line)
   oldsha=${array[0]}
   newsha=${array[1]}
   refname=${array[2]}
  # echo oldsha $oldsha newsha $newsha refname $refname
   if [ $newsha != $NULL_SHA1 ]
   then
   #  echo "will have to check Newsha"
     check_each_commit $newsha $refname
   fi
done < /dev/stdin


exit $status

