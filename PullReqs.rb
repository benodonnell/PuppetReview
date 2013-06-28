require 'Hashie'
require 'Octokit'

class GitFileEdit
	@@specRegex = /^spec\//
	@@fileNameRegex = /^(\.gemspec|Gemfile)$/
	@@lineChangeRegex = /(?<=\s|^-|^\+)\/dev\/null\b|\braise\b|(?<=\s|^-|^\+)\.write\b|(?<=\s|^-|^\+)%x\b|\bexec\b/ #The lookbehinds are necessary for the 2 words that start with punctuation since those are non-word characters for purposes of regex word boundaries. The lookbehinds need to match a + or - immediately before the punctuated word in case its at the very beginning of changed line, but not if its preceded by a + or - anywhere else in the line.
	
	attr_reader :filename
	attr_reader :patch
	attr_reader :interesting
	attr_reader :conservative
	attr_reader :in_spec
	
	def initialize(pullFile)
		@filename = pullFile[:filename]
		@patch = pullFile[:patch]
		@interesting = false
		@adds = {
			'/dev/null' => 0,
			'raise' => 0,
			'.write' => 0,
			'%x' => 0,
			'exec' => 0
		}
		@removes = {
			'/dev/null' => 0,
			'raise' => 0,
			'.write' => 0,
			'%x' => 0,
			'exec' => 0
		}
		@fileInstance = nil
		@in_spec = false
		determineInterest
	end
	
	#returns an array with the reason(s) a file is interesting. Or not.
	def reasons
		explain = []
		if @interesting then
			if @fileInstance then
				explain << @fileInstance.to_s
			end
			@adds.select{|key, value| value > 0}.each do |key, value|
				explanation = "#{key} added in #{value} place"
				if value > 1 then
					explanation += "s"
				end
				explanation += "."
				explain << explanation
			end
			@removes.select{|key, value| value > 0}.each do |key, value|
				explanation = "#{key} removed in #{value} place"
				if value > 1 then
					explanation += "s"
				end
				explanation += "."
				explain << explanation
			end
		else
			explain << "This file is uninteresting."
		end
		return explain
	end
	
=begin
This function determines whether a changed file is interesting. First, it looks at whether the file is in the directory spec/. Any file in spec/ is deemed uninteresting and the changes don't need to be analyzed.

If the file isn't in spec/, there are 2 ways for it to be interesting:
	1. The patch contains a changed line with one of the following (as a separate word):
		/dev/null
		raise
		.write
		%x
		exec
	OR
	2. The file is Gemfile or .gemspec. I am assuming we aren't interested in attempts to add these files anywhere other than the root directory.
=end
	def determineInterest
		if @filename.match(@@specRegex) then
			@interesting = false
			@in_spec = true
		else
			@filename.match(@@fileNameRegex){|m|
				@interesting = true
				@fileInstance = "#{m} has been changed"
			}
			if @patch.respond_to?("lines") then
				#some patches are nil in which case this code gets skipped.
				@patch.lines do |line|
					line.match(@@lineChangeRegex) { |m|
					case line[0]
						when '+' then @adds[m.to_s] += 1
						when '-' then @removes[m.to_s] += 1
					end	
					}
				end
			end
			@interesting = @interesting | @adds.any? {|k, v| v > 0} | @removes.any? {|k, v| v > 0} #this should set @interesting to true if it's already true, or if either @adds or @removes has a non-zero value. Otherwise, @interesting stays false.
		end
	end
end

class GitRequest
	attr_reader :url
	attr_reader :number
	attr_reader :title
	attr_reader :files
	attr_reader :interesting
=begin
Since the directions were slightly ambiguous about what to do if there was an otherwise interesting change in the same pull request as an uninteresting change to the spec/ directory, @conservative allows the object to process the information both ways.
If @conservative is true, then any pull request with a change to spec/ is deemed uninteresting, even if it has otherwise interesting file changes in it.
If @conservative is false, then a pull request with a change to spec/ will be deemed interesting if it has other interesting file changes.
=end
	attr_reader :conservative
	
	def initialize(pullReq, pullFiles, conservative = false)
		@url = pullReq[:html_url]
		@number = pullReq[:number]
		@title = pullReq[:title]
		@files = []
		@interesting = false
		@conservative = conservative
		pullFiles.each do |file|
			@files << (GitFileEdit.new(file))
		end
		determineInterest
	end
	
=begin
This function determines whether the pull request as a whole is interesting. First, if @conservative is true, then it looks to see whether any files in the request are in spec/. If they are, the entire request is uninteresting. If @conservative is false, or if there are no files in spec/, then it looks to see if at least one file change is interesting.
=end
	def determineInterest
		if @conservative && @files.find {|file| file.in_spec} then
			@interesting = false
			return
		end
		@interesting = @interesting || @files.any? {|file| file.interesting}
	end
	
	#Adds a file to the pull requests and redetermines interest.
	def addFile(file)
		if file.respond_to?("interesting") then
			@files << file
			determineInterest
		end
	end
end

=begin
This function takes a repository address (e.g. "puppetlabs/puppet" and an optional boolean value for "conservative" and fetches the necessary data through the Git API to populate an array of GitRequest objects, which it returns.
=end
def fetchPullRequests(repository, conservative = false)
	begin
		openRequests = []
		#get all open pull requests for the repository.
		rawPullReqs = Octokit.pull_requests(repository)
		#iterate through each request and create a GitRequest object and populate it with files obtained through a pull_requests_files call.
		rawPullReqs.each do |rawPull|
			rawFiles = Octokit.pull_request_files(repository, rawPull[:number])
			openRequests << GitRequest.new(rawPull, rawFiles, conservative)
		end
		return openRequests
	rescue Octokit::Error => e
		raise e
		#I'm going to let other errors slide for now.
	end
end