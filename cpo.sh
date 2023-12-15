#set -e #stop execution if error

rm nohup.out  #remove existing nohup.out file

narg=$#

in1="${1%/}"   #strip trailing slash if it exists so user doesn't have to think about it as input

curdir=$(pwd)
usrnm="$(basename "$(dirname "$curdir")")"      #find username, using quotes keeps spaces in path, if any
ch=${usrnm:0:1} #first charater of username

basepathsource=/n/scratch3/users/$ch/$usrnm/
pthsource=$basepathsource$in1/

basepathdest=/n/files/Neurobio/wilsonlab/


if test $narg -eq 3
then
  drystr="this is a dry run, nothing is copied"
  dryin="n"
  declare -i nargok=3
else
  drystr="this is NOT a dry run, things are being copied"
  dryin=""
  declare -i nargok=2
fi

echo $drystr

echo base path source is $basepathsource
echo base path destination is $basepathdest


if test $narg -eq $((nargok-1))         #if only one input besides optional dry
then
  pthdest=$basepathdest$in1
elif test $narg -eq $nargok     #if two inputs besides optional dry
then
  in2="${2%/}"  #strip trailing slash if it exists so user doesn't have to think about it as input
  pthdest=$basepathdest$in2
else
  echo "ERROR MUST HAVE 1-3 INPUT ARGUMENTS"
  exit 29293939
fi

echo copying files from $pthsource
echo into folder $pthdest
echo creating any nonexisting directories in destination path
echo skipping files with same name even if modified
echo $drystr

mkdir -p $pthdest          #make destination path if it doens't exist (including enclosing)


if test $narg -eq 3
then
  nohup rsync -rnv $pthsource $pthdest --ignore-existing &
else
  nohup rsync -rv $pthsource $pthdest --ignore-existing &
fi

