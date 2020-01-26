# !/bin/bash
 
# Script to compare  two directories/files - specific file patterns can be differentiated as well
# Should be installed with compareDirs.cfg in the same folder - sample provided with this archive
# For addition/modifications of any specific requirement , please contact am@abhijitm.org
 
if [ "$1" == "-h" ]
then
    echo "Usage ./compareDirs <options>"
    echo "Options :"
    echo "_________"
        echo "     no options "
        echo "              will use compareDirs.cfg as configuration file and will work on directory level"
        echo "              Please fill in the parameters in the file as per your requirements"
        echo "    -f <file1> <file2>"
        echo "              will find the difference between two files . But you dont really need a script to do that "
        echo "              You can use diff utility available on all flavour of linux/unix...Never mind !"
        exit 0
fi
 
printifDebugOn()
{
   stringToPrint="$1"
   if [ "${VERBOSE_ON}" == "Y" ]
   then
        echo "${stringToPrint}"
   fi
}
 
initialiseProcess()
{
 
   if [ ! -s ./compareDirs.cfg ]
   then
         echo "Empty or missing config file"
         exit 1 ;
   else
         chmod 777 ./compareDirs.cfg
   fi
 
 
   #read the config file
   . ./compareDirs.cfg
   echo "     +-------------------------------------------------------------------------------------------------------------------------------+"
   echo "     |    Working on $LHS_DIR "
   echo "     |                    and "
   echo "     |               $RHS_DIR "
   echo "     +-------------------------------------------------------------------------------------------------------------------------------+"
   printifDebugOn "[DEBUG]:Intialising ........"
 
   #Directories to be compared - read from config file
   lhsDirFullPath=$LHS_DIR
   rhsDirFullPath=$RHS_DIR
   #get the directory name
   lhsDir=`echo "$lhsDirFullPath"  | awk -F"/" '{print $NF}'`
   rhsDir=`echo "$rhsDirFullPath"  | awk -F"/" '{print $NF}'`
 
   #workDirectory - default value
   if [ "${WORK_DIR}" == "" ]
   then
       WORK_DIR=$HOME
   fi
 
   #clean work directory
   rm -f ${WORK_DIR}/FilesDiff*  ${WORK_DIR}/DirDiff*   ${WORK_DIR}/file_list_*
   printifDebugOn "[DEBUG]:Intialisation Complete."
}
 
getFileListInDir()
{
 
    DirToScanFullPath="$1"
        DirToScan=`echo "${DirToScanFullPath}"  | awk -F"/" '{print $NF}'`
        FILE_LIST=${WORK_DIR}/file_list_${DirToScan}
 
        if [ "${ONLY_SPECIFIC_FILE_PATTERN}" == "Y" ]
        then
             echo "Will only diff -->" ${FILE_PATTERN}
             find "${DirToScanFullPath}" -type f -name "${FILE_PATTERN}"|cut -d/ -f2- | sort | awk -F"/" '{print $NF}'| grep "${FILE_PATTERN}" > ${FILE_LIST}
        else
             find "${DirToScanFullPath}" -type f | cut -d/ -f2- | sort | awk -F"/" '{print $NF}' >  ${FILE_LIST}
        fi
}
 
diffDirs()
{
   printifDebugOn "[DEBUG]:Comparing Directories........."
 
   DIR_DIFF_REPORT=${WORK_DIR}/DirDiff.${lhsDir}.${lhsDir}
 
 
   #Check Difference if there are differenct in files' list i.e. any missing/additional files between two Directories
   if [ "${ONLY_SPECIFIC_FILE_PATTERN}" == "Y" ]
   then
       echo "Will only diff -->" ${FILE_PATTERN}
       diff -rq -I "ExportDate" ${lhsDirFullPath} ${rhsDirFullPath}  |  grep "${FILE_PATTERN}"  > ${DIR_DIFF_REPORT}
   else
       diff -rq -I "ExportDate" ${lhsDirFullPath} ${rhsDirFullPath}  | sort > ${DIR_DIFF_REPORT}
   fi
 
 
   #Extra details in verbose mode - not usually required as we are looking only for difference and not matches
   if [ "${VERBOSE_ON}" == "Y" ]
   then
        getFileListInDir "${lhsDirFullPath}"
        lhsDir_File_list=${FILE_LIST}
        getFileListInDir "${rhsDirFullPath}"
        rhsDir_File_list=${FILE_LIST}
 
        echo "files in ${rhsDir} that are also present in ${lhsDir} "
                grep -f ${lhsDir_File_list} ${rhsDir_File_list}
 
        echo "files in ${lhsDir} that are also present in ${rhsDir} "
                grep -f ${rhsDir_File_list}      ${lhsDir_File_list}
   fi
 
    printifDebugOn "[DEBUG]:Directory Comparision completed."
}
 
diffFiles()
{
   printifDebugOn "[DEBUG]:Starting File Comparison ........."
 
   FILE_DIFF_REPORT=${WORK_DIR}/FilesDiff.${lhsDir}.${lhsDir}
   grep differ ${DIR_DIFF_REPORT} | awk -F" " '{print $2 "  " $4}' >> ${FILE_DIFF_REPORT}.listOfFiles
 
   while read lhsFile rhsFile
   do
       echo "${lhsFile} | ${rhsFile}"                            >> ${FILE_DIFF_REPORT}
       diff -bBy  --suppress-common-lines -I "ExportDate"  ${lhsFile} ${rhsFile} >> ${FILE_DIFF_REPORT}
       echo "                       "                            >> ${FILE_DIFF_REPORT}
   done  < ${FILE_DIFF_REPORT}.listOfFiles
 
   printifDebugOn "[DEBUG]:Completed comparing files........."
}
 
 
#Main Flow
initialiseProcess
if [ "$1" == "-f" ]
then
    diff -bBy  --suppress-common-lines $1 $2  > ${WORK_DIR}/filesDiff.$$.lst
else
    diffDirs
    diffFiles
fi
 
 
if [ "${PRINT_OUTPUT_TO_CONSOL}" == "Y" ]
then
    echo " "
    echo " "
    echo "_________________________________________________________________Printing Summary_________________________________________________________________"
    cat ${DIR_DIFF_REPORT}
    echo " _________________________________________________________________________________________________________________________________________________"
    echo " "
    echo "_________________________________________________________________Printing Details_________________________________________________________________"
    cat ${FILE_DIFF_REPORT}
    echo " _________________________________________________________________________________________________________________________________________________"
    echo " "
else
    echo " "
        echo " Summary  : ${DIR_DIFF_REPORT} "
        echo " Detail   : ${FILE_DIFF_REPORT}"
fi
 
 
if [ "${SEND_EMAIL}" == "Y" ]
then
   DIR_DIFF_REPORT_FILE=`echo ${DIR_DIFF_REPORT} | awk -F"/" '{print $NF".txt"}'`
   FILE_DIFF_REPORT_FILE=`echo ${FILE_DIFF_REPORT} | awk -F"/" '{print $NF".txt"}'`
   ( uuencode  ${DIR_DIFF_REPORT}  ${DIR_DIFF_REPORT_FILE} ; uuencode ${FILE_DIFF_REPORT} ${FILE_DIFF_REPORT_FILE}  )  |
   mailx -s "Diff Report for ${lhsDir} and ${rhsDir} "  "${EMAIL_LIST}"
fi
 
exit 0 ;
