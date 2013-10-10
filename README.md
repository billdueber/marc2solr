# marc2solr -- get MARC data into Solr

> **Deprecated** `marc2solr` was very useful, but I've collaborated with Jonathan Rochkind on a new, improved JRuby-based indexing framework called [`traject`](https://github.com/traject-project/). Use it instead

___

___

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
