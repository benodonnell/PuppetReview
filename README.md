PuppetReview
============

1. Invocation
-------------
The file review is an executable ruby file. You should be able to run it by invoking ./review from the directory you downloaded this to, or by adding the directory it's in to your PATH.

2. Usage
--------
review has 2 options: `-c` and `-v`.

*      `-c` sets conservative mode. In this mode, an entire pullrequest will be marked uninteresting if it has any changes to files in the directory spec/. This is off by default.
*      `-v` sets verbose mode. Normally, review will print a list of pull requests and whether each request is interesting, but nothing more. When verbose is on, it will list the interesting changes in each pull request under the request's url.

And you can always use `-h` to print out the commands.

In addition to the 2 options, review requires at least 1 argument, which is the username followed by a slash followed by the repo you want to review. e.g.: `puppetlabs/puppet`.

You can specify as many repos as you like and review will examine them in sequence, although if they are large you will likely run out of API requests.

3. Work Needed
--------------
At present, review doesn't use credentials to make the api calls, so it will run up against the git api's limits on anonymous api calls per hour.
