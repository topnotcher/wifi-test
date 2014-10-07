require_relative 'wpa_cli.rb'
require 'pp'

class WifiTester
	def initialize(wpa)
		@wpa = wpa
	end

	def test_connect

	end

end

wpa = WpaCli.new('/usr/sbin/wpa_cli','/tmp/wpa','wlan0')

unless wpa.cmd_wait_status('disconnect', {'wpa_state' => 'DISCONNECTED'}) 
	puts "timeout while disconnecting from URI_Secure WTF?)"
else
	puts "Successfully disconnected from URI_Secure"
end


if wpa.cmd_wait_status('reconnect', {'ssid' => 'URI_Secure', 'wpa_state' => 'COMPLETED'})
	puts "Successfully connected to URI_Secure"
else
	puts "Timeout while connecting to URI_Secure"
end
