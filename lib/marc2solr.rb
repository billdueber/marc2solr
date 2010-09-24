require 'rubygems'
require 'logger'
require 'rjack-logback'


newlevel = nil
unless $LOG
  $LOG = RJack::SLF4J["marc2solr.gem" ]
  RJack::Logback['marc2solr.gem'].level = RJack::Logback::DEBUG
end

$LOG = RJack::SLF4J["marc2solr.gem" ]



module MARC2Solr
  
  class Configuration
        
    VALIDOPTIONS = [
      # What to do    
      :benchmark, :dry_run, :printmarc, :printdoc, :clearsolr, :commit,
      
      # output      
      :out,

      # Threading    
      :threads, :sussthreads,

      # Solr
      :machine, :port, :path, :javabin,
      
      # Log
      :logfile, :loglevel, :logbatchsize,
      
      # Input file characteristics
      :marctype, :encoding,
    ]
    
    
    def initialize
       
      @config = {}
      
      # Basic settings
      @config[:commit] = true
      @config[:out] = STDOUT
      @config[:threads] = 1
      @config[:sussthreads] = 1
      @config[:loglevel] = Logger::INFO
      @config[:logfile] = STDERR
      @config[:logbatchsize] = 10000
      @config[:marctype] = 'guess'
      @config[:encoding] = 'guess'
    end
    
    def pretty_print(pp)
      pp.pp @config
    end
    
    def method_missing(methodSymbol, arg=nil)
      methodSymbol = methodSymbol.to_s.gsub(/=$/, '').to_sym
      if VALIDOPTIONS.include? methodSymbol
        unless arg.nil?
          @config[methodSymbol] = arg 
          $LOG.warn "Set #{methodSymbol} to #{arg}"
          sleep 1
        end
        return @config[methodSymbol]
      else
        raise NoMethodError, "'#{methodSymbol} is not a valid MARC2Solr configuration option"
      end
    end
  end
end 

    
