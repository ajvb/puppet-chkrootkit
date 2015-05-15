require 'spec_helper'

describe 'chkrootkit' do
  it do 
    should contain_package('chkrootkit')
  end

  it 'should have an augeas resource' do
    should contain_augeas('configure-chkrootkit')
  end

  context 'with defaults' do
    it 'should define an absent file at /usr/local/bin/chkrootkit' do
      should contain_file('/usr/local/bin/chkrootkit') \
        .with_ensure('absent') 
    end

    it 'should define an absent cron entry' do
      should contain_cron('chkrootkit') \
        .with_ensure('absent') \
    end

    it 'should create the file /etc/cron.daily/chkrootkit' do
      should contain_file('/etc/cron.daily/chkrootkit') \
        .with_ensure('present')
        .with_content(/CHKROOTKIT=\/usr\/sbin\/chkrootkit/) \
        .with_content(/CF=\/etc\/chkrootkit.conf/) \
        .with_content(/LOG_DIR=\/var\/log\/chkrootkit/) \
        .with_content(/log.today/) \
        .with_content(/log.expected/) \
        .with_mode('0755') \
        .with_owner('root') \
        .with_group('root')
    end
  end

  context "with manage_cron == true" do
    context "with run_daily == false" do
      let :params do {
              :manage_cron    => true,
              :run_daily      => false,
      } end

      describe_augeas 'configure-chkrootkit', :lens => 'Shellvars', :target => 'etc/chkrootkit.conf' do
        it 'should contain RUN_DAILY="true"' do
          should execute.with_change
          aug_get('RUN_DAILY').should == '"true"'
          should execute.idempotently
        end
      end
    end

    let :params do {
            :manage_cron    => true,
            :run_daily      => true,
            :mailto         => 'nobody@example.com'
    } end

    it 'should ensure the default cron.daily is absent' do
      should contain_file('/etc/cron.daily/chkrootkit') \
        .with_ensure('absent') \
    end

    it 'should create the file /usr/local/bin/chkrootkit' do
      should contain_file('/usr/local/bin/chkrootkit') \
        .with_ensure('present')
        .with_content(/CHKROOTKIT=\/usr\/sbin\/chkrootkit/) \
        .with_content(/CF=\/etc\/chkrootkit.conf/) \
        .with_content(/LOG_DIR=\/var\/log\/chkrootkit/) \
        .with_content(/log.today/) \
        .with_content(/log.expected/) \
        .with_mode('0755') \
        .with_owner('root') \
        .with_group('root')
    end

    it 'should define a cron entry' do
      should contain_cron('chkrootkit') \
        .with_ensure('present') \
        .with_command('/usr/local/bin/chkrootkit') \
        .with_user('root') \
        .with_minute('25') \
        .with_hour('6') \
        .with_environment('MAILTO=nobody@example.com')
    end
  end

  context "with diff_mode == false" do
    let :params do {
            :diff_mode      => false,
    } end

    describe_augeas 'configure-chkrootkit', :lens => 'Shellvars', :target => 'etc/chkrootkit.conf' do
      it 'should change RUN_DAILY and DIFF_MODE' do
        should execute.with_change
        aug_get('DIFF_MODE').should == '"false"'
        should execute.idempotently
      end
    end
  end

  context "with diff_mode == true" do
    context "with manage_cron == true" do
      let :params do {
          :diff_mode        => true,
          :manage_cron      => true,
      } end
      it do
        should contain_exec('create-today-log') \
          .with_command('/usr/local/bin/chkrootkit') \
          .with_creates('/var/log/chkrootkit/log.today') \
          .with_require('File[/usr/local/bin/chkrootkit]') \
          .with_before('Exec[copy-today-log-to-expected-log]')
      end
    end

    context "with manage_cron == false" do
      let :params do {
          :diff_mode        => true,
          :manage_cron      => false,
      } end
      it do
        should contain_exec('create-today-log') \
          .with_command('/etc/cron.daily/chkrootkit') \
          .with_creates('/var/log/chkrootkit/log.today') \
          .with_require('File[/etc/cron.daily/chkrootkit]') \
          .with_before('Exec[copy-today-log-to-expected-log]')
      end
    end

    let :params do {
        :diff_mode      => true,
    } end

    describe_augeas 'configure-chkrootkit', :lens => 'Shellvars', :target => 'etc/chkrootkit.conf' do
      it 'should change RUN_DAILY and DIFF_MODE' do
        should execute.with_change
        aug_get('DIFF_MODE').should == '"true"'
        should execute.idempotently
      end
    end

    it do
      should contain_exec('copy-today-log-to-expected-log') \
        .with_command('/bin/cp /var/log/chkrootkit/log.today /var/log/chkrootkit/log.expected') \
        .with_creates('/var/log/chkrootkit/log.expected')
    end
  end
end
