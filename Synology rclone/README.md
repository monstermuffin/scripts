## Automated Rclone Synology Persistance/Backup

Scripts for installing/updating rclone on Synology DSM and scheduling bacukups.

Used in the blog post: https://blog.muffn.io/posts/scheduled-backups-using-rclone-on-synology-dsm/

These scripts ensure rclone is kept up to date on a Synology NAS, as well as recovers an installation after an upgrade which typically removes user installed packages. As well as this the script ensures config persistence, so you do not have to do anything after the initial setup. More information is in the blog post above.

### Features
* Backup multiple local directories to a remote directory.
* Support for various operation modes: copy, sync, or move.
* Customizable log levels and log file path.
* Exclusion and inclusion patterns for fine-grained control over backed up files.
* Bandwidth limit and transfer concurrency control.
* Retry mechanism for failed transfers.
* Dry run mode for testing and verification.
* Automatic installation and updating of rclone on a Synology NAS.
* Persistent rclone configuration across updates.

### Prerequisites
* rclone scripts setup as scheduled tasks on Synology DSM (see blog post).
* A properly configured rclone remote (referenced in the REMOTEDIR variable).
* Script `config` filled out.

### Configuration

The script relies on a configuration file `config` located in the same directory as the script. The configuration file should contain the following variables:

* `LOCALDIRS`: Comma-separated list of local directories to be backed up.
* `REMOTEDIR`: Remote directory destination for the backup (e.g., Google Drive).
* `OPERATION_MODE`: Operation mode for rclone (copy, sync, or move).
* `LOGLEVEL`: Log level for rclone (DEBUG, INFO, ERROR).
* `LOGFILE`: Path to the log file.
* `TRANSFER_LIMIT`: Number of file transfers to perform simultaneously.
* `EXCLUDE_PATTERNS`: Comma-separated list of exclude patterns.
* `EXCLUDE_IF_PRESENT`: Comma-separated list of filenames that, if present, will exclude a directory from backup.
* `INCLUDE_PATTERNS`: Comma-separated list of include patterns.
* `CUSTOM_FLAGS`: Space-separated list of custom rclone flags.
* `BWLIMIT`: Bandwidth limit for rclone transfers (e.g., "10M" for 10 MBytes/s, or leave empty for unlimited).
* `RETRIES`: Number of retries after a failed transfer.
* `RETRY_DELAY`: Delay between retries, in seconds.
* `CHECKERS`: Number of checkers to run in parallel (affects the speed of file checks).
* `DRY_RUN`: Enable dry run mode for testing (true or false).
* `VERBOSE`: Enable verbose output (true or false).

### Installation and Setup
If you are unsure how to use this then a full guide is available [on my blog.](https://blog.muffn.io/posts/scheduled-backups-using-rclone-on-synology-dsm/)

***Use this script at your own risk.*** Always test the script before using it in production.

For more information on rclone and its usage, please refer to the official rclone documentation: https://rclone.org/docs/
