# This class configures chkrootkit
#
# @example Standard configuration with Hiera
#   include '::chkrootkit'
#
#   chkrootkit::diff_mode: true
#   chkrootkit::config:
#     RUN_DAILY: 'true'
#     RUN_DAILY_OPTS: '-q'
#
# @example Standard configuration directly setting variables
#   class { 'chkrootkit':
#     diff_mode     => true,
#     config        => {
#       'RUN_DAILY'         => 'true',
#       'RUN_DAILY_OPTS'    => '-q',
#     }
#   }
#
# @param package [String] The name of the chkrootkit package.
# @param cron_script [String] The path to the script that cron will run.
# @param cron_template [String] The template to use for creating cron_script.
# @param cron_minute [Integer] The minute to pass to the cron entry.
# @param cron_hour [Integer] The hour to pass to the cron entry.
# @param cf [String] The path to chkrootkit.conf.
# @param chkrootkit [String] The path to the chkrootkit binary.
# @param log_dir [String] The path to the directory that the today log and expected log will be stored in.
# @param today_log [String] The name of the today log.
# @param expected_log [String] The name of the expected log.
# @param diff_mode [Boolean] Whether or not to operate in diff_mode.
# @param config [Hash] The changes to make to the chkrootkit configuration file. Augeas is used to implement the changes using the Shellvars lens.
# 
class chkrootkit (
    $package        = 'chkrootkit',
    $cron_script    = '/usr/local/bin/chkrootkit',
    $cron_template  = 'chkrootkit/chkrootkit.cron.erb',
    $cron_minute    = 25,
    $cron_hour      = 6,
    $cf             = '/etc/chkrootkit.conf',
    $chkrootkit     = '/usr/sbin/chkrootkit',
    $log_dir        = '/var/log/chkrootkit',
    $today_log      = 'log.today',
    $expected_log   = 'log.expected',
    $diff_mode      = false,
    $config         = {},
){
    validate_string($::chkrootkit::package)
    validate_absolute_path($::chkrootkit::cron_script)
    validate_string($::chkrootkit::cron_template)
    validate_integer($::chkrootkit::cron_minute)
    validate_integer($::chkrootkit::cron_hour)
    validate_absolute_path($::chkrootkit::cf)
    validate_absolute_path($::chkrootkit::chkrootkit)
    validate_absolute_path($::chkrootkit::log_dir)
    validate_string($::chkrootkit::today_log)
    validate_string($::chkrootkit::expected_log)
    validate_hash($::chkrootkit::config)

    ensure_packages($::chkrootkit::package)

    if $diff_mode {
        # lint:ignore:quoted_booleans
        $final_config = merge($::chkrootkit::config, { 'DIFF_MODE' => 'true' })
        # lint:endignore

        exec { 'create-today-log':
            command => $cron_script,
            creates => "${log_dir}/${today_log}",
            require => File[$cron_script],
            before  => Exec['copy-today-log-to-expected-log']
        }

        exec { 'copy-today-log-to-expected-log':
            command => "/bin/cp ${log_dir}/${today_log} ${log_dir}/${expected_log}",
            creates => "${log_dir}/${expected_log}"
        }
    } else {
        # lint:ignore:quoted_booleans
        $final_config = merge($::chkrootkit::config, { 'DIFF_MODE' => 'false' })
        # lint:endignore
    }

    $changes_array = join_keys_to_values($final_config, ' \'"')
    $changes_quoted = suffix($changes_array, '"\'')
    $changes = prefix($changes_quoted, 'set ')

    augeas { 'configure-chkrootkit':
        incl    => $::chkrootkit::cf,
        lens    => 'Shellvars.lns',
        changes => $::chkrootkit::changes,
        require => Package[$::chkrootkit::package]
    }

    file { '/etc/cron.daily/chkrootkit':
        ensure  => absent,
        require => Package[$::chkrootkit::package]
    }

    file { $cron_script:
        ensure  => present,
        content => template($cron_template),
        owner   => 'root',
        group   => 'root',
        mode    => '0755'
    }

    cron { 'chkrootkit':
        command => $cron_script,
        user    => 'root',
        minute  => $cron_minute,
        hour    => $cron_hour
    }
}
