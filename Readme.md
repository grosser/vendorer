Vendorer
========

 - documented & cached dependencies
 - automatic updates
 - no unwanted/accidental updates


Install
-------

Needs: Curl + Git + Ruby

then:

``` bash
gem install vendorer
```

or standalone
```Bash
curl https://rubinjam.herokuapp.com/pack/vendorer > vendorer && chmod +x vendorer
./vendorer -v
```


Usage
-----

Add a `Vendorfile` (or `Vendorfile.rb`) to your project root:


<!-- extracted by vendorer init -->
``` ruby
file 'vendor/assets/javascripts/jquery.min.js', 'http://code.jquery.com/jquery-latest.min.js'
folder 'vendor/plugins/parallel_tests', 'https://github.com/grosser/parallel_tests.git'

# Execute a block after updates
file 'vendor/assets/javascripts/jquery.js', 'http://code.jquery.com/jquery.js' do |path|
  puts "Do something useful with #{path}"
  rewrite(path) { |content| content.gsub(/\r\n/, \n).gsub /\t/, ' ' }
end

# Checkout a specific :ref/:tag/:branch
folder 'vendor/plugins/parallel_tests', 'https://github.com/grosser/parallel_tests.git', :tag => 'v0.6.10'

# DRY folders
folder 'vendor/assets/javascripts' do
  file 'jquery.js', 'http://code.jquery.com/jquery-latest.js'
end

# Copy files & folders from repos (also works with private repos)
from 'https://github.com/grosser/parallel_tests.git' do |checkout_location|
  file 'Readme.md'
  file 'target-folder/file.rb', 'lib/parallel_tests.rb'
  folder 'spec'
  folder 'renamed-folder', 'spec'
end
```
<!-- extracted by vendorer init -->

 - Create a new Vendorfile: `vendorer init`
 - excute all installations: `vendorer`
 - Update all dependencies: `vendorer update`
 - update a single dependency: `vendorer update vendor/assets/javascripts/jquery.min.js`
 - update everything in a specific folder: `vendorer update vendor/assets/javascripts`


Alternatives
============
 - [Vendorificator](https://github.com/3ofcoins/vendorificator) more features/complexity, but similar interface/concept

TODO
====
 - nice error message when no Vendorfile was found

Author
======

### [Contributors](http://github.com/grosser/vendorer/contributors)
 - [Kurtis Rainbolt-Greene](https://github.com/krainboltgreene)
 - [Ivan K.](https://github.com/divout)
 - [Matt Brictson](https://github.com/mbrictson)
 - [Andreas Haller](https://github.com/ahx)

[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/vendorer.png)](https://travis-ci.org/grosser/vendorer)
