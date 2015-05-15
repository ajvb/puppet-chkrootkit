# Chkrootkit

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with Chkrootkit](#setup)
    * [What Chkrootkit affects](#what-Chkrootkit-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with Chkrootkit](#beginning-with-Chkrootkit)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [Development - Guide for contributing to the module](#development)

## Overview

The Chkrootkit module installs and configures the Chkrootkit service.

## Module Description

Installs and configures chkrootkit. By default, it will download the package and remove the
default /etc/cron.daily entry and instead manage it with a Puppet cron type. If you set 
the `diff_mode` parameter to true, it will create an expected log on the next run. After the
first run, chkrootkit will compare its results to the expected log to determine if any
rootkits are present.

## Setup

### What Chkrootkit affects

Chkrootkit runs as a cron entry as root.

### Setup requirements

* Puppet-3.0.0 or later

### Beginning with Chkrootkit

include '::chkrootkit'

## Usage

Use Hiera or directly define class variables

### Hiera

Include the Class

````puppet
include '::chkrootkit'
```

Hiera Data

````puppet
chkrootkit::diff_mode: true
chkrootkit::run_daily: true
chkrootkit::run_daily_opts: '-q'
```

### Define variables explicitly

Include the Class

````puppet
class { 'chkrootkit':
    diff_mode       => true,
    run_daily       => true,
    run_daily_opts  => '-q'
}
```

## Reference

### Classes

#### Public Classes

* [chkrootkit](#chkrootkit): The Chkrootkit class

#### `chkrootkit`

### Parameters

#### `chkrootkit::package`

The name of the chkrootkit package.

Default: 'chkrootkit'

#### `chkrootkit::manage_cron`

Whether or not to manage the cron entry. If set to false, the default daily cron entry
will remain. If set to true, an entry will be made in the root user's crontab. The values
of this entry will be determined by cron_minute, cron_hour, and mailto.

default: false

#### `chkrootkit::cron_script`

The path to the script that cron will run.

Default: /usr/local/bin/chkrootkit

#### `chkrootkit::cron_template`

The template to use for creating cron_script

Default: 'chkrootkit/chkrootkit.cron.erb'

#### `chkrootkit::cron_minute`

The minute to pass to the cron entry

Default: 25

#### `chkrootkit::cron_hour`

The hour to pass to the cron entry

Default: 6

#### `chkrootkit::cf`

The path to chkrootkit.conf.

Default: /etc/chkrootkit.conf

#### `chkrootkit::chkrootkit`

The path to the chkrootkit binary

Default: /usr/sbin/chkrootkit

#### `chkrootkit::log_dir`

The path to the directory that the today log and expected log will be stored in.

Default: /var/log/chkrootkit

#### `chkrootkit::today_log`

The name of the today log.

Default: log.today

#### `chkrootkit::expected_log`

The name of the expected log.

Default: log.expected

#### `chkrootkit::diff_mode`

Whether or not to operate in diff_mode.

Default: false

#### `chkrootkit::run_daily`

Sets the RUN_DAILY parameter in chkrootkit.conf.

Default: false

#### `chkrootkit::run_daily_opts`

Sets the RUN_DAILY_OPTS parameter in chkrootkit.conf

Default: '-q'


#### `chkconfig::mailto`

The user to send emails to. This optional parameter only matters if manage_cron is true.

Default: undef
