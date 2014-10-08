require_relative 'wpa_cli.rb'
require_relative 'dhcp.rb'
require 'logger'
require 'pp'
require 'time'

logger = Logger.new('wifi-test.log')
wpa = WpaCli.new('/usr/sbin/wpa_cli','/tmp/wpa','wlan0')
dhcp = DHCP.new('/sbin/dhclient', 'wlan0')
dhcp.set_logger(logger)
wpa.set_logger(logger)

tests = [wpa, dhcp]

while true
	logger.info("Starting connection tests")
	start_time = Time.new
	status = 'OKAY'
	sleep_time = 0
	tests.each do |test|
		unless test.send :test
			status = 'FAIL'
			break
		end
		sleep 1
		sleep_time += 1
	end
	logger.info("Connection tests %s; duration: %.3f" % [status,Time.new - start_time-sleep_time])	
		
	wpa.cmd 'disconnect'

	sleep 300
end
