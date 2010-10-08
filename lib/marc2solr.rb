require 'rubygems'

require 'logback-simple'
require 'trollop'
require 'ftools'
require 'jruby_streaming_update_solr_server'
require 'marc4j4r'

module MARC2Solr
  
  class Conf
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
     [:NObenchmark, {:desc=> "Benchmark production of each solr field",
                   :only=> [:index],
                  }],
     [:dryrun,   {:desc => "Don't send anything to solr",
                    }],
      [:NOdryrun,   {:desc => "Disable a previous 'dryrun' directive",
                    }],
                    
      [:printmarc, {:desc =>"Print MARC Record (as text) to --debugfile",
                    :only => [:index],
                    :short => '-r'
                    }],
      [:NOprintmarc, {:desc =>"Turn off printing MARC Record (as text) to --debugfile",
                    :only => [:index],
                    }],
      [:printdoc,  {:desc => "Print each completed document to --debugfile", 
                    :only => [:index],
                    :short => '-d'}
      ],
      [:NOprintdoc,  {:desc => "Turn off printing each completed document to --debugfile", 
                    :only => [:index],
                    }],      
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
      [:threads,   {:desc => "Number of threads to use to process MARC records (>1 => use 'threach')", 
                    :type => :int,
                    :default => 1,
                    :only => [:index]
                    }],                    
      [:sussthreads, {:desc => "Number of threads to send completed docs to Solr", 
                      :type => :int,
                      :default => 1}],
      [:susssize,    {:desc => "Size of the documente queue for sending to Solr", 
                      :short => '-S',
                      :default => 128}],
      [:machine, {:desc => "Name of solr machine (e.g., solr.myplace.org)",
                      :short => '-m',
                      # :required => [:index, :commit, :delete],
                      :type => String}],
      [:port,        {:desc => "Port of solr machine (e.g., '8088')", 
                    :short => '-p',
                    :type => :int}],
      [:solrpath,  {:desc => "URL path to solr",
                    :short => '-P',
                   }],
      [:javabin, {:desc => "Use javabin (presumes /update/bin is configured in schema.xml)", 
                      }],                      
      [:NOjavabin, {:desc => "Don't use javabin", 
                      }],                      
      [:logfile,   {:desc => "Name of the logfile (filename, 'STDERR', 'DEFAULT', or 'NONE'). 'DEFAULT' is a file based on input file name", 
                    :default => "DEFAULT",
                    :takesNone => true,                    
                    :type => String}],
      [:loglevel, {:desc=>"Level at which to log (DEBUG, INFO, WARN, ERROR, OFF)",
                   :short => '-L',
                   :takesNone => true,
                   :valid => %w{OFF DEBUG INFO WARN ERROR },
                   :default => 'INFO'}],
      [:logbatchsize, {:desc => "Write progress information to logfile after every N records",
                       :default => 25000,
                       :only => [:delete, :index],
                       :short => '-b'}],
      [:indexfile, {:desc => "The index file describing your specset (usually index.rb)",
                    :type => String,
                    :only => [:index],
                    }],
      [:tmapdir,   {:desc => "Directory that contains any translation maps",
                    :type => String,
                    :only => [:index]
                    }],
      [:customdir, {:desc=>"The directory containging custom routine libraries (usually the 'lib' next to index.rb). Repeatable",
                    :only => [:index],
                    :multi => true,
                    :type => String
                    }],
      [:marctype, {:desc => "Type of marc file ('bestguess', 'strictmarc'. 'marcxml', 'alephsequential', 'permissivemarc')",
                   :only => [:index],
                   :short => '-t',
                   :valid => %w{bestguess strictmarc permissivemarc marcxml alephsequential },
                   :default => 'bestguess'
                   }],      
      [:encoding, {:desc => "Encoding of the MARC file ('bestguess', 'utf8', 'marc8', 'iso')",
                   :valid => %w{bestguess utf8 marc8 iso},
                   :only => [:index],
                   :default => 'bestguess'}],
      [:gzipped, {:desc=>"Is the input gzipped? An extenstion of .gz will always force this to true",
                  :default => false,
                  :only => [:index, :delete],
                  }]

    ]
    
    VALIDOPTIONS = {}
    OPTIONSCONFIG.each {|a| VALIDOPTIONS[a[0]] = a[1]}
    
    
    HELPTEXT = {
      'help'  => "Get help on a command\nmarc2solr help <cmd> where <cmd> is index, delete, or commit",
      'index' => "Index the given MARC file\nmarc2solr index --config <file> --override <marcfile> <marcfile2...>",
      'delete' => "Delete based on ID\nmarc2solr delete --config <file> --override <file_of_ids_to_delete> <another_file...>",
      'commit' => "Send a commit to the specified Solr\nmarc2solr commit --config <file> --override",
    }
    
    attr_accessor :config, :cmdline, :rest, :command
    def initialize
      @config = {}
      @cmdline = command_line_opts
      
      # Load the config files
      if @cmdline[:config]
        @cmdline[:config].each do |f|
          log.info "Reading config-file '#{f.path}'"
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
    
    def [] arg
      return @config[arg]
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
    
  Use "marc2solr <cmd> --help" for more help

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
        
    
    def pretty_print(pp)
      pp.pp @config
    end
    
    def method_missing(methodSymbol, arg=:notgiven, fromCmdline = false)
      return @config[methodSymbol] if arg == :notgiven
      methodSymbol = methodSymbol.to_s.gsub(/=$/, '').to_sym
      
      # Deal with negatives. We only want them if the argument is true
      if methodSymbol.to_s =~ /^NO(.*)/
        if arg == true
          methodSymbol = $1.to_sym
          arg = false
        else
          # puts "Ignoring false-valued #{methodSymbol}"
          return # do nothing
        end
      end
      
      # puts "   Setting #{methodSymbol} to #{arg}"
      if VALIDOPTIONS.has_key? methodSymbol
        conf = VALIDOPTIONS[methodSymbol]
        # Zero it out?
        if conf[:takesNone] and arg.to_a.map{|a| a.downcase}.include? 'none'
          @config[methodSymbol] = nil 
          return nil
        end
        
        
        # Check for a valid value
        if conf[:valid]
          unless conf[:valid].include? arg
            raise ArgumentError "'#{arg}' is not a valid value for #{methodSymbol}"
          end
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
            arg = File.new(arg, 'w')
            Trollop.die "Can't open '#{arg}' for writing in argument #{methodSymbol}" unless arg
          end
        end
            
        
        if conf[:multi]
          @config[methodSymbol] ||= []
          @config[methodSymbol] << arg
          @config[methodSymbol].flatten!
        else
          @config[methodSymbol] = arg 
        end
        # puts "Set #{methodSymbol} to #{arg}"
        return @config[methodSymbol]
      else
        raise NoMethodError, "'#{methodSymbol} is not a valid MARC2Solr configuration option for #{@cmd}"
      end
    end
    
    
    # Create a SUSS from the given arguments
    
    def sussURL
      machine = self[:machine] 
      unless machine 
        log.error  "Need solr machine name (--machine)"
        raise ArgumentError, "Need solr machine name (--machine)"
      end
      
      port = self[:port] 
      unless port
        log.error "Need solr port (--port)"
        raise ArgumentError, "Need solr port (--port)"
      end
      
      path = self[:solrpath]
      unless path
        log.error "Need solr path (--solrpath)"
        raise ArgumentError, "Need solr path (--solrpath)"
      end
      
      url = 'http://' + machine + ':' + port + '/' + path.gsub(/^\//, '')
    end
    
    def suss
      url = self.sussURL
      log.debug "Set suss url to #{url}"

      suss = StreamingUpdateSolrServer.new(url,@config[:susssize],@config[:sussthreads])
      if self[:javabin]
        suss.setRequestWriter Java::org.apache.solr.client.solrj.impl.BinaryRequestWriter.new
        log.debug "Using javabin"
      end
      return suss
    end
      
    def masterLogger
      mlog = Logback::Simple::Logger.singleton(self.command)
      mlog.loglevel = @config[:loglevel].downcase.to_sym

      firstfile = self.rest[0] || self.command
      logfilename = File.basename(firstfile).gsub(/\..*$/, '') # remove the last extension
      logfilename += '-' +  Time.new.strftime('%Y%m%d-%H%M%S') + '.log'

      Logback::Simple.loglevel = @config[:loglevel].downcase.to_sym
      case @config[:logfile]
      when "STDERR"
        Logback::Simple.startConsoleLogger
      when "DEFAULT"
        Logback::Simple.startFileLogger(logfilename)
      when 'NONE', nil
        # do nothing
      else
        Logback::Simple.startFileLogger(@config[:logfile])
      end
      return mlog
    end
    
    
    def reader filename
      configuredType = @config[:marctype].downcase.to_sym
      encoding = @config[:encoding].downcase.to_sym
      
      if encoding == :bestguess
        encoding = nil
      end
      
      gzipped = false
      if configuredType == :bestguess
        if filename =~ /\.(.+)$/ # if there's an extension
          ext = File.basename(filename).split(/\./)[-1].downcase
          if ext == 'gz'
            ext  = File.basename(filename).split(/\./)[-2].downcase
            gzipped = true
          end          
          
          log.info "Sniffed marc file type as #{ext}"
          case ext
          when /xml/, /marcxml/
            type = :marcxml
          when /seq/, /aleph/
            type = :alephsequential
          else
            type = :permissivemarc
          end
        else
          type = :permissivemarc
        end
      else
        type = configuredType
      end

      source = filename
      if source == "STDIN"
        source = STDIN
      end

      if gzipped or @config[:gzipped]
        source = Java::java.util.zip.GZIPInputStream.new(IOConvert.byteinstream(source))
      end
      
      return MARC4J4R::Reader.new(source, type, encoding)
    end
    
    
  end
end 

    
