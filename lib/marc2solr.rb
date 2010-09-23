require 'rubygems'
require 'logger'

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
    
    def method_missing(methodSymbol, arg=nil)
      methodSymbol = methodSymbol.to_s.gsub(/=$/, '').to_sym
      if VALIDOPTIONS.include? methodSymbol
        unless arg.nil?
          @config[methodSymbol] = arg 
          puts "Set #{methodSymbol} to #{arg}"
        end
        return @config[methodSymbol]
      else
        raise NoMethodError, "'#{methodSymbol} is not a valid MARC2Solr configuration option"
      end
    end
  end
end 

    
