## The Debt Sheet

This repo contains a full test suite, but only skeletal code, for an
application to track purchases and payments between members of a group.

You task is to fill out the code, such that the full test suite passes.  The
test suite is designed to be run in a particular order, guiding you through the
process of writing the code.

You should run the test suite like this:

    $ bin/rspec --fail-fast spec/ordered_specs.rb

or on Windows like this:

    $ bin\rspec --fail-fast spec/ordered_specs.rb

This will cause rspec to fail as soon as it hits the first failing spec.  When
you make the spec pass, run the test suite to ensure you haven't broken
anything, and move onto the next failing spec. 
