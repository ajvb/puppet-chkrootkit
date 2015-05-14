require 'spec_helper'

describe 'chkrootkit' do
  context 'with defaults' do
    it do 
      should contain_package('chkrootkit')
    end

    it 'should have an augeas resource' do
      should contain_augeas('configure-chkrootkit')
    end

    it 'should ensure the default cron.daily is absent' do
      should contain_file('/etc/cron.daily/chkrootkit') \
        .with_ensure('absent') \
        .with_require('Package[chkrootkit]')
    end

    it 'should create the executable file /usr/local/bin/chkrootkit' do
      should contain_file('/usr/local/bin/chkrootkit') \
        .with_content(/CHKROOTKIT=\/usr\/sbin\/chkrootkit/) \
        .with_content(/CF=\/etc\/chkrootkit.conf/) \
        .with_content(/LOG_DIR=\/var\/log\/chkrootkit/) \
        .with_content(/log.today/) \
        .with_content(/log.expected/) \
        .with_mode('0755') \
        .with_owner('root') \
        .with_group('root')
    end

    it 'should create a cron entry' do
      should contain_cron('chkrootkit') \
        .with_command('/usr/local/bin/chkrootkit') \
        .with_user('root') \
        .with_minute('25') \
        .with_hour('6')
    end
  end

  context "diff_mode is false" do
    let :params do {
      :config => {
          'RUN_DAILY' => 'true',
	      'RUN_DAILY_OPTS' => '-q',
          'DIFF_MODE' => 'true'
        }
    } end

    describe_augeas 'configure-chkrootkit', :lens => 'Shellvars', :target => 'etc/chkrootkit.conf' do
      it 'should change RUN_DAILY and DIFF_MODE' do
        should execute.with_change
        aug_get('DIFF_MODE').should == '"false"'
        should execute.idempotently
      end
    end
  end

  context "diff_mode is true" do
    let :params do {
      :config => {
          'RUN_DAILY' => 'true',
          'RUN_DAILY_OPTS' => '-q',
          'DIFF_MODE' => 'true'
        }, :diff_mode => true
    } end

    describe_augeas 'configure-chkrootkit', :lens => 'Shellvars', :target => 'etc/chkrootkit.conf' do
      it 'should change RUN_DAILY and DIFF_MODE' do
        should execute.with_change
        aug_get('DIFF_MODE').should == '"true"'
        should execute.idempotently
      end
    end

    it do
      should contain_exec('create-today-log') \
        .with_command('/usr/local/bin/chkrootkit') \
        .with_creates('/var/log/chkrootkit/log.today') \
        .with_require('File[/usr/local/bin/chkrootkit]') \
        .with_before('Exec[copy-today-log-to-expected-log]')
    end

    it do
      should contain_exec('copy-today-log-to-expected-log') \
        .with_command('/bin/cp /var/log/chkrootkit/log.today /var/log/chkrootkit/log.expected') \
        .with_creates('/var/log/chkrootkit/log.expected')
    end
  end
end
