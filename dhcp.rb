require 'open3'
require 'time'

class DHCP 
	def initialize(dhclient, interface) 
		@dhclient = dhclient
		@interface = interface
	end

	def run
		begin_dhcp_test
		dhcpin,dhcpout,wait_thr = Open3.popen2e('%s -nc -1 -d -lf /dev/null -sf /tmp/dhcp.sh %s' % [@dhclient, @interface])

		dhcpout.each_line do |line|
			handle_data line.strip
			break if @dhcp_done
		
		end

		end_dhcp_test
		dhcpin.close
		dhcpout.close
		Process.kill("QUIT", wait_thr[:pid])
		wait_thr.value
		puts "returned"
	end

	def begin_dhcp_test
		@read_env = false
		@dhcp_done = false
		@dhcp_counts = {}
		@start_time = Time.new
	end

	def end_dhcp_test
		duration = Time.new - @start_time

		if @dhcp_config and @dhcp_config.has_key? 'new_ip_address'
			status = "OKAY ip:%s from:%s" % [
				@dhcp_config['new_ip_address'],
				@dhcp_config['new_dhcp_server_identifier']
			] 
		else
			status = "FAIL"
		end

		
		log "DHCP test %s; Duration: %.3fs; %s" % [status,duration,dhcp_count_summary]
	end

	def handle_data(line)
		if line == '---- DHCP START ----'
			start_env
		elsif line == '---- DHCP END ----'
			end_env
		elsif is_env_line
			handle_env(line)
		else
			handle_dhcp_output(line)
		end
	end

	def handle_dhcp_output(line)
		if line =~ /^bound to/
			@dhcp_done = true
			log line
		elsif line =~ /^DHCP/
			log line
			count_dhcp_request(line)
		elsif line =~ /^Sending on/
			log line
		end
	end

	def dhcp_count_summary
		count_strs = []
		@dhcp_counts.each do |k,v|
			count_strs << "%s: %d" % [k,v]
		end
		count_strs.join ','
	end

	def count_dhcp_request(line)
		type = line.split(' ', 2)[0] #[4,line.size-1]
		@dhcp_counts[type] ||= 0
		@dhcp_counts[type] += 1
	end

	def is_env_line
		@read_env
	end

	def handle_env(line)
		k,v = line.split('=',2)
		@dhcp_config ||= {}
		@dhcp_config[k] = v
	end

	def start_env
		@dhcp_config = nil
		@read_env = true
	end

	def end_env
		@read_env = false
	end

	def log(line)
		puts "%s: %s" % [Time.new.inspect, line]
	end
end
