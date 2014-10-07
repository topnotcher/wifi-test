class WpaCli
	def initialize(wpa_cli, sock_path, interface)
		@wpa = WpaCliConn.new(wpa_cli, sock_path, interface)
	end

	def status
		status = {}
		@wpa.cmd('status').each_line do |line|
			line.strip!
			k,v = line.split('=',2)
			status[k] = v
		end
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
