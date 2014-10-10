<a href="http://tweetcounts.herokuapp.com/" target="_blank">Tweetcounts</a>

## Running The Software

* Download the repo in your local computer.
* In terminal/command line, cd to the root directory of this project
* Run `cp .env.example .env`
* Enter your own TWITTER_API_KEY and TWITTER_API_SECRET to the matching line in `.env` file
* bundle install --without production
* rerun -x rackup
* In browser, visit "localhost:9292"
