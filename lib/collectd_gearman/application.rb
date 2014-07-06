require 'optparse'
require 'yaml'
require 'ostruct'

module CollectdGearman

  class Application
    
    CONF_FILE = "/etc/collectd/nagios.yaml"
    SEND_GEARMAN_BIN = "/usr/bin/send_gearman"

    def self.run
      standard_exception_handling do
        handle_options
        data = read_stdin
        send_commands data
      end
    end

    def self.options
      @options ||= OpenStruct.new
    end

    def self.handle_options
      parse_args
      read_conf
      set_defaults
      check_params
    end

    def self.parse_args
      options.config_file = CONF_FILE

      OptionParser.new do |opts|
        opts.banner = "Usage: collectd_gearman [options]"

        opts.on('-f', '--config FILE', 'Config file') { |v| options.config_file = v }
        opts.on('-s', '--server SERVER', 'Gearman server') { |v| options.gearman_server = v }
        opts.on('-k', '--key KEY', 'Gearman key') { |v| options.gearman_key = v }
        opts.on('-g', '--send_gearman BIN', 'send_gearman binary') { |v| options.send_gearman = v }
        opts.on('-l', '--log_file FILE', 'log file') { |v| options.log_file = v }
        opts.on('-v', '--verbose', 'verbose') { |v| options.verbose = v }

        opts.on_tail("-h", "--help", "-H", "Display this help message.") do
          puts opts
          exit
        end

      end.parse!
    end

    def self.read_conf
      return unless File.exist?(options.config_file)
      file_config = YAML.load_file(options.config_file)
      file_config.each do |k,v|
        options.send("#{k}=",v) unless options.send(k)
      end
    end
    
    def self.set_defaults
      options.send_gearman ||= SEND_GEARMAN_BIN
    end

    def self.check_params
      raise "Gearman server must be defined" unless options.gearman_server
      raise "Gearman key must be defined" unless options.gearman_key
    end

    # Read threshold data from Collectd
    def self.read_stdin
      data = {}
      ARGF.each do |line|
        if line =~ /^[a-zA-Z]+: .*/
          data.merge!({line.split(": ").first => line.split(": ").last.strip})
        else
          data.merge!(message: line.strip)
        end
      end
    
      # DataSource = value is the same as nothing
      data.delete("DataSource") if data["DataSource"] == "value"
      data
    end
    
    # Send passive checks to all posible services
    def self.send_commands(data)
      # Plugin-Instance.Type-Instance.DataSource
      # Plugin-Instance.Type-Instance
      # Plugin-Instance.Type.DataSource
      # Plugin-Instance.Type
      # Plugin.Type-Instance.DataSource
      # Plugin.Type-Instance
      # Plugin.Type.DataSource
      # Plugin.Type

      if data["PluginInstance"] and data["TypeInstance"] and data["DataSource"]
        send_gearman data["Host"],data[:message],data["Severity"],"collectd_#{data["Plugin"]}-#{data["PluginInstance"]}.#{data["Type"]}-#{data["TypeInstance"]}.#{data["DataSource"]}"
      end
      
      if data["PluginInstance"] and data["TypeInstance"]
        send_gearman data["Host"],data[:message],data["Severity"],"collectd_#{data["Plugin"]}-#{data["PluginInstance"]}.#{data["Type"]}-#{data["TypeInstance"]}"
      end
      
      if data["PluginInstance"] and data["DataSource"]
        send_gearman data["Host"],data[:message],data["Severity"],"collectd_#{data["Plugin"]}-#{data["PluginInstance"]}.#{data["Type"]}.#{data["DataSource"]}"
      end
      
      if data["PluginInstance"]
        send_gearman data["Host"],data[:message],data["Severity"],"collectd_#{data["Plugin"]}-#{data["PluginInstance"]}.#{data["Type"]}"
      end
      
      if data["TypeInstance"] and data["DataSource"]
        send_gearman data["Host"],data[:message],data["Severity"],"collectd_#{data["Plugin"]}.#{data["Type"]}-#{data["TypeInstance"]}.#{data["DataSource"]}"
      end
      
      if data["TypeInstance"]
        send_gearman data["Host"],data[:message],data["Severity"],"collectd_#{data["Plugin"]}.#{data["Type"]}-#{data["TypeInstance"]}"
      end
      
      if data["DataSource"]
        send_gearman data["Host"],data[:message],data["Severity"],"collectd_#{data["Plugin"]}.#{data["Type"]}.#{data["DataSource"]}"
      end
      
      send_gearman data["Host"],data[:message],data["Severity"],"collectd_#{data["Plugin"]}.#{data["Type"]}"
    end
    
    def self.send_gearman(host,message,severity,service)
      case severity
      when "FAILURE"
        return_code = 2
      when "WARNING"
        return_code = 1
      when "OKAY"
        return_code = 0
      else
        return_code = 3
      end
    
      cmd = "#{options.send_gearman} --server=\"#{options.gearman_server}\" --encryption=yes --key=\"#{options.gearman_key}\" --host=\"#{host}\" --service=\"#{service}\" --message=\"#{message.gsub('"',"'")}\" -r=#{return_code}"

      raise "Command not found: #{options.send_gearman}" unless File.exist?(options.send_gearman)
      
      puts cmd if options.verbose

      if options.log_file
        File.open(options.log_file,"a") do |f|
          f << "[#{Time.now}] #{cmd}\n"
        end
      end

      system cmd
    end
    
    def self.standard_exception_handling
      yield
    rescue SystemExit
      # Exit silently with current status
      raise
    rescue Exception => ex
      $stderr.puts ex.message
      exit(false)
    end
  end
end
