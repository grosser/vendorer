Vendorer
========

 - documented dependencies
 - automatic updates
 - no unwanted/accidental updates


Install
-------

1. Curl
2. Git v1.7
3. Ruby v1.8.7, v1.9.2, or v1.9.3

To install vendorer simply use:

``` bash
$ gem install vendorer
```

Or add it to your `Gemfile`:

``` ruby
group :development do
  gem 'vendorer'
end
```


Usage
-----

Add a `Vendorfile` to your project root:


``` ruby
file 'vendor/assets/javascripts/jquery.min.js', 'http://code.jquery.com/jquery-latest.min.js'
folder 'vendor/plugins/parallel_tests', 'https://github.com/grosser/parallel_tests.git'

# Execute a block after updates
file 'vendor/assets/javascripts/jquery.js', 'http://code.jquery.com/jquery.js' do |path|
  puts "Do something useful with #{path}"
  rewrite(path) { |content| content.gsub(/\r\n/, \n).gsub /\t/, ' ' }
end

# Checkout a specific :ref/:tag/:branch
folder 'vendor/plugins/parallel_tests', 'https://github.com/grosser/parallel_tests.git', tag: 'v0.6.10'

# DRY folders
folder 'vendor/assets/javascripts' do
  file 'jquery.js', 'http://code.jquery.com/jquery-latest.js'
end
```


Call `vendorer install` or just `vendorer` to excute all of the installations.
Update all dependencies with `vendorer update` or a single dependency with `vendorer update vendor/assets/javascripts/jquery.min.js`.
You can even update everything in a specific folder: `vendorer update vendor/assets/javascripts`.


TODO
====
 - nice error message when no Vendorfile was found

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://secure.travis-ci.org/grosser/vendorer.png)](http://travis-ci.org/grosser/vendorer)
