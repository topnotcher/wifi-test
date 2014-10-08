require 'time'

class WpaCli
	def initialize(wpa_cli, sock_path, interface)
		@wpa = WpaCliConn.new(wpa_cli, sock_path, interface)
		@logger = nil
	end

	def set_logger(logger)
		@logger = logger
	end

	def log(type, line)
		@logger.send(type, line) if @logger
	end

	def test
		start_time = Time.new


		# always be sure pmk is not cached between checks
		# this needs to be < the check interval
		cmd 'set dot11RSNAConfigPMKLifetime=200'

		# just in case - always start with the supplicant disconnected
		unless cmd_wait_status('disconnect', {'wpa_state' => 'DISCONNECTED'}) 
			log :error, "timeout while disconnecting from URI_Secure WTF?"
			return false
		end


		unless cmd_wait_status('reconnect', {'ssid' => 'URI_Secure', 'wpa_state' => 'COMPLETED'})
			log :error, "Timeout while connecting to URI_Secure"
			return false
		end

		duration = Time.new - start_time
		log :info, "Successfully connected to (%s,%s); duration: %.3fs" % [@last_status['ssid'],@last_status['bssid'], duration]

		return true
	end

	def status
		status = {}
		@wpa.cmd('status').each_line do |line|
			line.strip!
			k,v = line.split('=',2)
			status[k] = v
		end
		@last_status = status
		return status
	end

	def cmd cmd
		@wpa.cmd cmd
	end

	def cmd_wait_status(cmd, status_checks)
		cmd cmd

		(1..60).each do |i|
			sleep 1
			return true if check_status(status_checks)
		end

		return false
	end

	def check_status(values) 
		result = status

		values.each do |k,v|
			return false unless result.has_key? k and result[k] = v
		end

		return true
	end
end

class WpaCliConn

	@@prompt = /^> $/

	def initialize(wpa_cli, sock_path, interface)
		@wpa_cli = wpa_cli
		@sock_path = sock_path
		@interface = interface

		@buf = ''
		@line = ''
		@log = ''
	end

	def cmd(cmd) 
		IO.popen('%s -p %s -i %s %s' % [@wpa_cli, @sock_path, @interface, cmd]).read.strip
	end
end
