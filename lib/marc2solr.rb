require 'rubygems'
require 'logback-simple'
require 'trollop'
require 'ftools'

module MARC2Solr
  
  class Configuration
    include Logback::Simple
    
    SUB_COMMANDS = %w(index delete commit help)
    
    
    OPTIONSCONFIG = [
      [:config,    {:desc => "Configuation file specifying options. Repeatable. Command-line arguments always override the config file(s)",
                    :type => :io,
                    :multi => true}],
      [:benchmark, {:desc=> "Benchmark production of each solr field",
                    :only=> [:index],
                    :short => '-B'
                   }],
      [:dryrun,   {:desc => "Don't send anything to solr",
                    :only => [:index]
                    }],
      [:printmarc, {:desc =>"Print MARC Record (as text) to --debugfile",
                    :only => [:index],
                    :short => '-r'
                    }],        
      [:printdoc,  {:desc => "Print each completed document to --debugfile", 
                    :only => [:index],
                    :short => '-d'}
      ],
      [:debugfile, {:desc => "Where to send output from --printmarc and --printdoc (takes filename, 'STDERR', 'STDOUT', or 'NONE') (repeatable)", \
                    :default => "STDOUT",
                    :isOutfile => true,
                    :takesNone => true,
                    :type => String, 
                    :only => [:delete, :index],
                    }],
      [:clearsolr, {:desc => "Clean out Solr by deleting everything in it (DANGEROUS)",
                    :only => [:index]
                    }],
      [:skipcommit,    {:desc => "DON'T send solr a 'commit' afterwards", 
                    :short => '-C',
                    :only => [:delete, :index],
                    }],
      [:threads,   {:desc => "Number of threads to use to process MARC records", 
                    :type => :int,
                    :default => 1,
                    :only => [:index]
                    }],                    
      [:sussthreads, {:desc => "Number of threads to send completed docs to Solr", 
                      :type => :int,
                      :only => [:delete, :index],
                      :default => 1}],
      [:susssize,    {:desc => "Size of the documente queue for sending to Solr", 
                      :short => '-S',
                      :only => [:delete, :index],                      
                      :default => 128}],
      [:machine, {:desc => "Name of solr machine (e.g., solr.myplace.org)",
                      :short => '-m',
                      # :required => [:index, :commit, :delete],
                      :type => String}],
      [:port,        {:desc => "Port of solr machine (e.g., '8088')", 
                    :short => '-p',
                    # :required => [:index, :commit, :delete],
                    :default => 8088,
                    :type => :int}],
      [:solrpath,  {:desc => "URL path to solr",
                    :short => '-P',
                    # :required => [:index, :commit, :delete],
                    :default => "solr/biblio"}],
      [:javabin, {:desc => "Use javabin (presumes /update/bin is configured in schema.xml)", 
                      }],                      
      [:logfile,   {:desc => "Name of the logfile (filename, 'STDOUT', 'STDERR', or 'NONE')", 
                    :default => "NONE",
                    :isOutfile => true,
                    :takesNone => true,                    
                    :type => String}],
      [:loglevel, {:desc=>"Level at which to log (DEBUG, INFO, WARN, ERROR, NONE)",
                   :short => '-L',
                   :takesNone => true,
                   :default => 'INFO'}],
      [:logbatchsize, {:desc => "Write progress information to logfile after every N records",
                       :default => 25000,
                       :only => [:delete, :index],
                       :short => '-b'}],
      [:marctype, {:desc => "Type of marc file ('bestguess', 'marcbinary'. 'marcxml', 'alephsequential', 'permissivemarc')",
                   :only => [:index],
                   :short => '-t',
                   :default => 'bestguess'
                   }],      
      [:encoding, {:desc => "Encoding of the MARC file ('bestguess', 'utf8', 'marc8', 'iso')",
                   :only => [:index],
                   :default => 'bestguess'}]

    ]
    
    VALIDOPTIONS = {}
    OPTIONSCONFIG.each {|a| VALIDOPTIONS[a[0]] = a[1]}
    
    
    HELPTEXT = {
      'help'  => "Get help on a command\nmarc2solr help <cmd> where <cmd> is index, delete, or commit",
      'index' => "Index the given MARC file\nmarc2solr index --config <file> --override <marcfile>",
      'delete' => "Delete based on ID\nmarc2solr delete --config <file> --override <file_of_ids_to_delete>",
      'commit' => "Send a commit to the specified Solr\nmarc2solr commit --config <file> --override",
    }
    
    attr_accessor :config, :cmdline, :rest, :command
    def initialize
      @config = {}
      @cmdline = command_line_opts
      
      # Load the config files
      if @cmdline[:config]
        @cmdline[:config].each do |f|
          log.debug "Reading config-file ''#{f.path}'"
          self.instance_eval(f.read)
        end
      end
      
      # Remove the config
      # Now override with the command line
      @cmdline.delete :config
      @cmdline.delete :config_given
      
      # Remove any "help" stuff 
      @cmdline.delete_if {|k, v| k.to_s =~ /^help/}

      # Keep track of what was passed on cmdline
            
      @cmdline_given = {}
      @cmdline.keys.map do |k|
        if k.to_s =~ /^(.+?)_given$/
          @cmdline_given[$1.to_sym] = true
          @cmdline.delete(k)
        end
      end
      
      @cmdline.each_pair do |k,v|
        if @cmdline_given[k]
          # puts "Send override #{k} = #{v}"
          self.send(k,v) 
        else
          unless @config.has_key? k
            # puts "Send default #{k} = #{v}"
            self.send(k,v) 
          end
        end
      end
      
      @rest = ARGV
    end
    
    
    def command_line_opts
      @command = ARGV.shift # get the subcommand
      
      # First, deal with the help situations
      unless SUB_COMMANDS.include? @command
        puts "Unknown command '#{@command}'" if @command
        print_basic_help
      end
      
      if ARGV.size == 0 
        print_basic_help
      end
      
      if @command== 'help'
        @command= ARGV.shift
        if SUB_COMMANDS.include? @cmd
          print_command_help @cmd
        else
          print_basic_help
        end
      end

      # OK. Now let's actuall get and return the args
      #
      # Trollop is a DSL and doesn't see our local instance variable, so I 
      # need to alias @commandto cmd
      
      cmd = @command
      return Trollop::options do
        OPTIONSCONFIG.each do |opt|
          k = opt[0]
          d = opt[1]
          next if d[:only] and not d[:only].include? cmd.to_sym
          desc = d.delete(:desc)
          opt k, desc, d
        end
      end
    end
    
    
    def print_basic_help
      puts %Q{
  marc2solr: get MARC data into Solr
  
  USAGE
    marc2solr index (index MARC records into Solr)
    marc2solr delete (delete by ID from Solr)
    marc2solr commit (send a 'commit' to a solr install)
    
  Use "marc2solr help <cmd>" for more help

}
      Process.exit
    end
    
    def print_command_help cmd
      ARGV.unshift '--help'
      Trollop::options do
        puts "\n\n" + HELPTEXT[cmd] + "\n\n"
        puts "You may specify multiple configuration files and they will be loaded in"
        puts "the order given."
        puts ""
        puts "Command line arguments always override configuration file settings\n\n"
        
        OPTIONSCONFIG.each do |opt|
          k = opt[0]
          d = opt[1]
          next if d[:only] and not d[:only].include? cmd.to_sym
          desc = d.delete(:desc)
          opt k, desc, d
        end
      end
      print "\n\n"
      Process.exit
      
    end
    
    
    
    def loadConfig filename
      f = File.open(filename)
      raise ArgumentError, "Can't open configuration file `#{filename}`" unless f
      log.debug "Reading config-file ''#{filename}'"
      self.instance_eval(f.read)
    end
    
    
    def pretty_print(pp)
      pp.pp @config
    end
    
    def method_missing(methodSymbol, arg=:notgiven, fromCmdline = false)
      return @config[methodSymbol] if arg == :notgiven
      methodSymbol = methodSymbol.to_s.gsub(/=$/, '').to_sym
      # puts "   Setting #{methodSymbol} to #{arg}"
      if VALIDOPTIONS.has_key? methodSymbol
        conf = VALIDOPTIONS[methodSymbol]
        # Zero it out?
        if conf[:takesNone] and arg.to_a.map{|a| a.downcase}.include? 'none'
          @config[methodSymbol] = nil 
          return nil
        end
        
        # Make it a file?
        
        if conf[:isOutfile]
          # If it's an IO object, just take it
          break if arg.is_a? IO or arg.is_a? StringIO
          
          # Otherwise...
          case arg.downcase
          when "stdin"
            arg = STDIN
          when "stdout"
            arg = STDOUT
          when "stderr"
            arg = STDERR
          else
            if File.writable? arg
              arg = File.new(arg, 'w')
            else
              # raise ArgumentError, "Can't open file '#{arg}"
              Trollop.die "Can't open '#{arg}' for writing in argument #{methodSymbol}"
            end
          end
        end
            
        
        if conf[:multi]
          @config[methodSymbol] ||= []
          @config[methodSymbol] << arg
          @config[methodSymbol].flatten!
        else
          @config[methodSymbol] = arg 
        end
        log.debug "Set #{methodSymbol} to #{arg}"
        return @config[methodSymbol]
      else
        raise NoMethodError, "'#{methodSymbol} is not a valid MARC2Solr configuration option for #{@cmd}"
      end
    end
  end
end 

    
