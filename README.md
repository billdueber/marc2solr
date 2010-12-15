# any2solr -- get data into Solr


`any2solr` is a basic command-line framework designed to make it easier to get data into Solr using JRuby and a thin ruby wrapper around some solrj functionality. 

Essentially, `any2solr` provides a little infrastructure around configuration and command-line arguments.

## OVERVIEW

### Available actions

* `any2solr index` -- index the given data using the given configuration options
* `any2solr delete` -- delete document associated with each given ID
* `any2solr commit` -- send a commit to the configured solr

### Code the user must provide (via configuration) for indexing

* A method that returns a data `reader` that responds to `#each` with a complete record (i.e., an object that includes the set of fields from which you'll put data into Solr)
* A method that takes a record from the `reader` and returns a `Hash` or (even better) a `SolrInputDocument` ready to sent to Solr.
 
### What any2solr provides

`any2solr` provides ways to configure (via configuration file or command-line) the following:

* Target solr installation (machine/port/path, whether to use javabin)
* Debugging output (output the record, the resulting solr doc, or both)
* Logging choices (level/location)
* A --dryrun option for testing without sending anything to solr
* Choice to clean out Solr before indexing, and/or send a commit afterwards
* Number of threads to use to process data (--threads) and send data to solr (--sussthreads)






`marc2Solr` is a package wrapping up functionality in a variety of other gems, designed to make getting data from [MARC21](http://en.wikipedia.org/wiki/MARC_standards) files into [Solr](http://lucene.apache.org/Solr/) as painless as possible.

`marc2Solr` is based on [Solrmarc](http://code.google.com/p/solrmarc/), the excellent Java-based program that does more or less the same thing. `marc2Solr` is *not* a drop-in replacement for Solrmarc, but can do most of the same things. A naive program to translate solrmarc config files to marc2solr config files is included. It's called -- wait for it -- solrmarc_to_marc2solr.

It relies on [jruby](http://jruby.org/) to pull it all together; this will not run under stock Ruby!

## Documentation

* [The marc2solr wiki]() has documentation on how to install, configure, and use `marc2solr`, how it compares to `solrmarc`, etc.
* The [marc2solr_example](http://github.com/billdueber/marc2solr_example) git project has two examples: `simple_sample` has a very simple index and some translation maps that show off the major features with plenty of documentation. The `umich` subdirectory is the actual working code for the University of Michigan [mirlyn](http://mirlyn.lib.umich.edu/) install.
* The [marcspec wiki](http://github.com/billdueber/marcspec/wiki/) is the definitive source for how to construct your index file, translation maps, and custom functions.



## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 BillDueber. See LICENSE for details.
