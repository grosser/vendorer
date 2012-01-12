Vendorer
========

 - documented dependencies
 - automatic updates
 - no unwanted/accidental updates


Install
-------

Ensure you have:

 - Curl
 - Git v1.7+
 - Ruby v1.8.7 or v1.9.2+

then:

``` bash
$ gem install vendorer
```

Or add vendorer to your `Gemfile`:

``` ruby
gem 'vendorer', :group => :development
```


Usage
-----

Add a `Vendorfile` to your project root:


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
```
<!-- extracted by vendorer init -->

 - Create a new Vendorfile: `vendorer init`
 - excute all installations: `vendorer`
 - Update all dependencies: `vendorer update`
 - update a single dependency: `vendorer update vendor/assets/javascripts/jquery.min.js`
 - update everything in a specific folder: `vendorer update vendor/assets/javascripts`


TODO
====
 - nice error message when no Vendorfile was found

Author
======

### [Contributors](http://github.com/grosser/vendorer/contributors)
 - [Kurtis Rainbolt-Greene](https://github.com/krainboltgreene)

[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://secure.travis-ci.org/grosser/vendorer.png)](http://travis-ci.org/grosser/vendorer)
