#!/bin/bash
DATE=`date +%Y-%m-%d`
cd /var/tools/confscript_b8
./circuitQuant.pl
./a925.pl
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
#./freqAlloc.pl
#./achannel.pl
#./n7AlignCheck.pl
#./siteConfig.pl
#./confsheets.pl
#./diffAcie.pl
#cp /var/tools/confscript_b8/output/csv/btsConfig.csv /var/www/html/confsheets/history/complete_sector_info/sector_info_$DATE.csv
#cp /var/www/html/confsheets/multi_bcch.html /var/www/html/confsheets/history/bcch_on_multirate/multiRate_$DATE.html
#cp /var/tools/confscript_b8/output/csv/dt16.csv /var/www/html/confsheets/history/dt16_diagnostic/dt16_problem_$DATE.csv
#cp /var/tools/confscript_b8/output/csv/rslConfig.csv /var/www/html/confsheets/history/rslConfig/rslConfig_$DATE.csv
#cp /var/tools/confscript_b8/output/csv/rslSummary.csv /var/www/html/confsheets/history/rslSummary/rslSummary_$DATE.csv
#cp /var/tools/confscript_b8/output/csv/abisSummary.csv /var/www/html/confsheets/history/rslSummary/abisSummary_$DATE.csv
exit 0

