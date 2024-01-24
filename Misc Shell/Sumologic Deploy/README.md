Quick and dirty shell script to:

    * Remove Alienvault agent (osqueryd)
    * Install Sumologic agent to all machines in `machines.txt`

SSH user/pass must be the same on all machines. The console output does have some confusing messages regarding the alienvault agent due to this going through several revisions however it does work as intended.

Token installation was attempted at first but proved to be unreliable, so access ID/Key was substituted.

Also, I don't really know why I included the dry run functionality, it doesn't really work. If anything it should be run at first to add all the machine endpoint keys to the local server.