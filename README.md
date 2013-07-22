rabbit-mq-consumers
===================

set of separate rabbit MQ consumers

running the test using nailgun
==============================

Start a nailgun server in the background:

    jruby --ng-server &

then you can run a single test using:

    jruby --ng -S rspec /path/to/spec

alternatively add the file:

    jspec

to your path and run:

    jspec /path/to/spec
