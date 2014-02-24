check_siteconfidence
====================

Nagios plugin written in Ruby to check the status of a Site Confidence user journey or page test and output the total time as performance data


`Usage: check_siteconfidence.rb --username <username> --password <password> --label <label of the user jouney/page to check>`

`OK: Site OK - Test at 09:41:27 of XXXX took 48.335s, result code 1 | total=48.335 step01=9.762 step02=0.2 step03=4.807 step04=0.338 step05=0.2 step06=0.261 step07=1.487
step08=17.231 step09=4.064 step10=2.541
Step 01: Site OK - Go to home page - 9.762s
Step 02: Site OK - Fill in form - 0.2s
Step 03: Site OK - Some other step - 4.807s
Step 04: Site OK - Some other step - 0.338s
Step 05: Site OK - Some other step - 0.2s
Step 06: Site OK - Some other step - 0.261s
Step 07: Site OK - Some other step - 1.487s
Step 08: Site OK - Some other step - 17.231s
Step 09: Site OK - Some other step - 4.064s
Step 10: Site OK - Some other step - 2.541s
https://portal.siteconfidence.co.uk/mon/report/script/script.php?st=0&sid=XXX`
