#!/bin/bash
DATE=`date +%Y-%m-%d`
./ftpconf.pl -f rnl
./ftpconf.pl -f eml
./ftpconf.pl -f ml
./circuitQuant.pl
./gpu.pl
./showDT16problem.pl
./multiRate_BCCH.pl
./bscConfig.pl
./sdcchConfig.pl
./btsConfig.pl
./abisSummary.pl
./addPsInfo.pl
./abisReport.pl
./tc.pl
./freqAlloc.pl
./achannel.pl
./n7AlignCheck.pl
./siteConfig.pl
./confsheets.pl
./vodCountRep.pl
./gprsRep.pl
./dpInfo.pl
./bscParamCompare.pl -f "g2ParameterComparison.html" -b WES_CTE_ST01
./bscParamCompare.pl -f "mxParameterComparison.html" -b EAS_PFR_FR07 -t evolution
cp /home/tools/confscript/output/csv/btsConfig.csv /var/www/html/confsheets/history/complete_sector_info/sector_info_$DATE.csv
cp /var/www/html/confsheets/multi_bcch.html /var/www/html/confsheets/history/bcch_on_multirate/multiRate_$DATE.html
cp /home/tools/confscript/output/csv/dt16.csv /var/www/html/confsheets/history/dt16_diagnostic/dt16_problem_$DATE.csv
cp /home/tools/confscript/output/csv/rslConfig.csv /var/www/html/confsheets/history/rslConfig/rslConfig_$DATE.csv
cp /home/tools/confscript/output/csv/rslSummary.csv /var/www/html/confsheets/history/rslSummary/rslSummary_$DATE.csv
cp /home/tools/confscript/output/csv/abisSummary.csv /var/www/html/confsheets/history/rslSummary/abisSummary_$DATE.csv
cp /home/tools/confscript/output/csv/abisReport.csv /var/www/html/confsheets/history/abisReport/abisReport_$DATE.csv
exit 0

