Vendorer

 - documented dependencies
 - automatic updates
 - no unwanted/accidental updates

Install
=======
Install curl and git, then:

    sudo gem install vendorer

Usage
=====
Add a `Vendorfile` to your project root:

    file 'public/javascripts/jquery.min.js', 'http://code.jquery.com/jquery-latest.min.js'
    folder 'vendor/plugins/parallel_tests', 'https://github.com/grosser/parallel_tests.git'

    # execute a block after updates
    file 'public/javascripts/jquery.js', 'http://code.jquery.com/jquery.js' do |path|
      puts "Do something useful with #{path}"
      rewrite(path){|content| content.gsub(/\r\n/,\n).gsub(/\t/,'  ') }
    end

    # checkout a specific :ref/:tag/:branch
    folder 'vendor/plugins/parallel_tests', 'https://github.com/grosser/parallel_tests.git', :tag => 'v0.6.10'

    # DRY folders
    folder 'public/javascripts' do
      file 'jquery.js', 'http://code.jquery.com/jquery-latest.js'
    end

Call `vendorer`

If you added something new: `vendorer`

Update all dependencies: `vendorer update`

Update one dependencies: `vendorer update public/javascripts/jquery.min.js`

Update everything in a folder: `vendorer update public/javascripts`


TODO
====
 - nice error message when no Vendorfile was found

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://secure.travis-ci.org/grosser/vendorer.png)](http://travis-ci.org/grosser/vendorer)
