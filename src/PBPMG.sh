#!/bin/sh

#/******************************************************************************
#* Copyright (c) 2013, 2015  Ericsson AB
#* All rights reserved. This program and the accompanying materials
#* are made available under the terms of the Eclipse Public License v1.0
#* which accompanies this distribution, and is available at
#* http://www.eclipse.org/legal/epl-v10.html
#*
#* Contributors:
#* Gabor Szalai
#******************************************************************************/

AWKARGS=$@
AVPSCRIPT="PBPMG.awk"

if [ $# -lt 1 ]; then 
  echo "ERROR: Too few arguments"
  echo "Usage: $0 <proto files>"
  echo ""
  exit 1
fi

     # check gawk version
     FIRSTLINE=`gawk --version|head -1`
     PRODUCT=`echo ${FIRSTLINE} | gawk '{ print $1 $2 }'`
     VERSION=`echo ${FIRSTLINE} | gawk '{ print $3 }'`
     if [ ${PRODUCT} != "GNUAwk" ]; then
       echo "ERROR: GNU Awk required"
       exit 1
     fi
     RESULT=`echo ${VERSION} | gawk '{ print ($0 < "3.1.6") }'`
     if [ ${RESULT} != 0 ]; then
       echo "ERROR: GNU Awk version >3.1.6 required (${VERSION} found)"
       exit 1
     fi

     comm_name=`which $0`
     comm_dir_name=`dirname $comm_name`

     gawk -f  ${comm_dir_name}/${AVPSCRIPT} ${AWKARGS}
     
     
