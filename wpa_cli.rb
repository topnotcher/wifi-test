require 'thread'
require'open3'

class WpaCli
	def initialize(wpa_cli, sock_path, interface)
		@wpa = WpaCliConn.new(wpa_cli, sock_path, interface)
		@wpa.connect
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

	def flush_log
		@wpa.flush_log
	end
end

class WpaCliConn

	@@prompt = /^> $/

	def initialize(wpa_cli, sock_path, interface)
		@wpa_cli = wpa_cli
		@sock_path = sock_path
		@interface = interface

		@mutex = Mutex.new
		@cv = ConditionVariable.new

		@buf = ''
		@line = ''
		@log = ''
	end

	def connect
		@state = :new
		@last_cmd = nil
		
		@in,@out,@err,@thr = Open3.popen3('%s -p %s -i %s' % [@wpa_cli, @sock_path, @interface])

		run
	end

	def cmd(cmd) 
		@line = ''
		@buf = ''

		@in.write(cmd + "\r")
		
		@mutex.synchronize {
			@cv.signal
			@cv.wait(@mutex,30)
		}

		return @buf.strip
	end

	def run
		@mutex.synchronize {
			Thread.new { read_data }
			@cv.wait(@mutex,30)
		}
	end

	def read_data 
		while (c = @out.getc())
			handle_data c
		end
	end

	def flush_log
		tmp = @log
		@log = ''
		return tmp
	end
	
	def handle_data(c)
		@line += c
		
		if c == "\n"
			# @TODO "log" lines seem to be prefixed with \r<[0-9]>.
			# I should probably save them somewhere.
			unless @line =~ /^\r<[0-9]>/
				puts "line: "+@line.strip
				@buf += @line
			else 
				puts "LOG: "+@line.strip
				@log += @line.lstrip
			end
			@line = ''
		elsif @line =~ @@prompt
			@line = ''
			@mutex.synchronize {
				@cv.signal
				@cv.wait(@mutex)
			}
		end
	end

	def close
		@in.write "quit\r"
		@in.close
		@out.close
		@err.close
		@mutex.synchronize { @cv.signal }
		@thr.value
	end
end
