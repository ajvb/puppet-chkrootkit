# This class configures chkrootkit
#
# @example Standard configuration with Hiera
#   include '::chkrootkit'
#
#   chkrootkit::diff_mode: true
#   chkrootkit::run_daily: true:
#   chkrootkit::run_daily_opts: '-q'
#
# @example Standard configuration directly setting variables
#   class { 'chkrootkit':
#     diff_mode         => true,
#     run_daily         => true,
#     run_daily_opts    => '-q',
#   }
#
# @param package [String] The name of the chkrootkit package.
# @param manage_cron [Boolean] Whether or not chkrootkit will run through cron
# @param cron_script [String] The path to the script that cron will run.
# @param cron_template [String] The template to use for creating cron_script.
# @param cron_minute [Integer] The minute to pass to the cron entry.
# @param cron_hour [Integer] The hour to pass to the cron entry.
# @param cf [String] The path to chkrootkit.conf.
# @param chkrootkit [String] The path to the chkrootkit binary.
# @param log_dir [String] The path to the directory that the today log and expected log will be stored in.
# @param today_log [String] The name of the today log.
# @param expected_log [String] The name of the expected log.
# @param diff_mode [Boolean] Sets the DIFF_MODE parameter in chkrootkit.conf
# @param run_daily [Boolean] Sets the RUN_DAILY parameter in chkrootkit.conf
# @param run_daily_opts [String] Sets the RUN_DAILY_OPTS parameter in chkrootkit.conf
# @param mailto [String] Optional email address to set in root's crontab. Only matters when manage_cron is set.
# 
class chkrootkit (
    $package        = 'chkrootkit',
    $manage_cron    = false,
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
    $run_daily      = false,
    $run_daily_opts = '-q',
    $mailto         = undef
){
    validate_string($::chkrootkit::package)
    validate_bool($::chkrootkit::manage_cron)
    validate_absolute_path($::chkrootkit::cron_script)
    validate_string($::chkrootkit::cron_template)
    validate_integer($::chkrootkit::cron_minute)
    validate_integer($::chkrootkit::cron_hour)
    validate_absolute_path($::chkrootkit::cf)
    validate_absolute_path($::chkrootkit::chkrootkit)
    validate_absolute_path($::chkrootkit::log_dir)
    validate_string($::chkrootkit::today_log)
    validate_string($::chkrootkit::expected_log)
    validate_bool($::chkrootkit::diff_mode)
    validate_bool($::chkrootkit::run_daily)
    validate_string($::chkrootkit::run_daily_opts)
    validate_string($::chkrootkit::mailto)

    ensure_packages($::chkrootkit::package)

    if $::chkrootkit::manage_cron {
        $chkrootkit_cmd = $cron_script
        $ensure_cron_daily = 'absent'
        $ensure_cron_managed = 'present'
    } else {
        $chkrootkit_cmd = '/etc/cron.daily/chkrootkit'
        $ensure_cron_daily = 'present'
        $ensure_cron_managed = 'absent'
    }

    # lint:ignore:quoted_booleans
    if $::chkrootkit::run_daily or $::chkrootkit::manage_cron {
        $run_daily_str = 'true'
    } else {
        $run_daily_str = 'false'
    }

    $config = { 'RUN_DAILY'         => $run_daily_str,
                'RUN_DAILY_OPTS'    => $::chkrootkit::run_daily_opts }

    if $::chkrootkit::diff_mode {
        $final_config = merge($config, { 'DIFF_MODE' => 'true' })

        exec { 'create-today-log':
            command => $chkrootkit_cmd,
            creates => "${log_dir}/${today_log}",
            require => File[$chkrootkit_cmd],
            before  => Exec['copy-today-log-to-expected-log']
        }

        exec { 'copy-today-log-to-expected-log':
            command => "/bin/cp ${log_dir}/${today_log} ${log_dir}/${expected_log}",
            creates => "${log_dir}/${expected_log}"
        }
    } else {
        $final_config = merge($::chkrootkit::config, { 'DIFF_MODE' => 'false' })
    }
    # lint:endignore

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
        ensure  => $ensure_cron_daily,
        content => template($cron_template),
        owner   => 'root',
        group   => 'root',
        mode    => '0755'
    }

    file { $cron_script:
        ensure  => $ensure_cron_managed,
        content => template($cron_template),
        owner   => 'root',
        group   => 'root',
        mode    => '0755'
    }

    cron { 'chkrootkit':
        ensure      => $ensure_cron_managed,
        command     => $cron_script,
        user        => 'root',
        minute      => $cron_minute,
        hour        => $cron_hour,
        environment => "MAILTO=${mailto}"
    }
}
